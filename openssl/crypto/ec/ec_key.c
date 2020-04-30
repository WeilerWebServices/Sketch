/* crypto/ec/ec_key.c */
/*
 * Written by Nils Larsch for the OpenSSL project.
 */
/* ====================================================================
 * Copyright (c) 1998-2005 The OpenSSL Project.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit. (http://www.openssl.org/)"
 *
 * 4. The names "OpenSSL Toolkit" and "OpenSSL Project" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission. For written permission, please contact
 *    openssl-core@openssl.org.
 *
 * 5. Products derived from this software may not be called "OpenSSL"
 *    nor may "OpenSSL" appear in their names without prior written
 *    permission of the OpenSSL Project.
 *
 * 6. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit (http://www.openssl.org/)"
 *
 * THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE OpenSSL PROJECT OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 *
 * This product includes cryptographic software written by Eric Young
 * (eay@cryptsoft.com).  This product includes software written by Tim
 * Hudson (tjh@cryptsoft.com).
 *
 */
/* ====================================================================
 * Copyright 2002 Sun Microsystems, Inc. ALL RIGHTS RESERVED.
 * Portions originally developed by SUN MICROSYSTEMS, INC., and
 * contributed to the OpenSSL project.
 */

#include <internal/cryptlib.h>
#include <string.h>
#include "ec_lcl.h"
#include <openssl/err.h>
#ifndef OPENSSL_NO_ENGINE
# include <openssl/engine.h>
#endif

EC_KEY *EC_KEY_new(void)
{
    return EC_KEY_new_method(NULL);
}

EC_KEY *EC_KEY_new_by_curve_name(int nid)
{
    EC_KEY *ret = EC_KEY_new();
    if (ret == NULL)
        return NULL;
    ret->group = EC_GROUP_new_by_curve_name(nid);
    if (ret->group == NULL) {
        EC_KEY_free(ret);
        return NULL;
    }
    if (ret->meth->set_group != NULL
        && ret->meth->set_group(ret, ret->group) == 0) {
        EC_KEY_free(ret);
        return NULL;
    }
    return ret;
}

void EC_KEY_free(EC_KEY *r)
{
    int i;

    if (r == NULL)
        return;

    i = CRYPTO_add(&r->references, -1, CRYPTO_LOCK_EC);
#ifdef REF_PRINT
    REF_PRINT("EC_KEY", r);
#endif
    if (i > 0)
        return;
#ifdef REF_CHECK
    if (i < 0) {
        fprintf(stderr, "EC_KEY_free, bad reference count\n");
        abort();
    }
#endif

    if (r->meth->finish != NULL)
        r->meth->finish(r);

#ifndef OPENSSL_NO_ENGINE
    if (r->engine != NULL)
        ENGINE_finish(r->engine);
#endif

    CRYPTO_free_ex_data(CRYPTO_EX_INDEX_EC_KEY, r, &r->ex_data);
    EC_GROUP_free(r->group);
    EC_POINT_free(r->pub_key);
    BN_clear_free(r->priv_key);

    OPENSSL_clear_free((void *)r, sizeof(EC_KEY));
}

EC_KEY *EC_KEY_copy(EC_KEY *dest, EC_KEY *src)
{
    if (dest == NULL || src == NULL) {
        ECerr(EC_F_EC_KEY_COPY, ERR_R_PASSED_NULL_PARAMETER);
        return NULL;
    }
    if (src->meth != dest->meth) {
        if (dest->meth->finish != NULL)
            dest->meth->finish(dest);
#ifndef OPENSSL_NO_ENGINE
        if (dest->engine != NULL && ENGINE_finish(dest->engine) == 0)
            return 0;
        dest->engine = NULL;
#endif
    }
    /* copy the parameters */
    if (src->group != NULL) {
        const EC_METHOD *meth = EC_GROUP_method_of(src->group);
        /* clear the old group */
        EC_GROUP_free(dest->group);
        dest->group = EC_GROUP_new(meth);
        if (dest->group == NULL)
            return NULL;
        if (!EC_GROUP_copy(dest->group, src->group))
            return NULL;
    }
    /*  copy the public key */
    if (src->pub_key != NULL && src->group != NULL) {
        EC_POINT_free(dest->pub_key);
        dest->pub_key = EC_POINT_new(src->group);
        if (dest->pub_key == NULL)
            return NULL;
        if (!EC_POINT_copy(dest->pub_key, src->pub_key))
            return NULL;
    }
    /* copy the private key */
    if (src->priv_key != NULL) {
        if (dest->priv_key == NULL) {
            dest->priv_key = BN_new();
            if (dest->priv_key == NULL)
                return NULL;
        }
        if (!BN_copy(dest->priv_key, src->priv_key))
            return NULL;
    }

    /* copy the rest */
    dest->enc_flag = src->enc_flag;
    dest->conv_form = src->conv_form;
    dest->version = src->version;
    dest->flags = src->flags;
    if (!CRYPTO_dup_ex_data(CRYPTO_EX_INDEX_EC_KEY,
                            &dest->ex_data, &src->ex_data))
        return NULL;

    if (src->meth != dest->meth) {
#ifndef OPENSSL_NO_ENGINE
        if (src->engine != NULL && ENGINE_init(src->engine) == 0)
            return NULL;
        dest->engine = src->engine;
#endif
        dest->meth = src->meth;
    }

    if (src->meth->copy != NULL && src->meth->copy(dest, src) == 0)
        return NULL;

    return dest;
}

EC_KEY *EC_KEY_dup(EC_KEY *ec_key)
{
    EC_KEY *ret = EC_KEY_new_method(ec_key->engine);

    if (ret == NULL)
        return NULL;
    if (EC_KEY_copy(ret, ec_key) == NULL) {
        EC_KEY_free(ret);
        return NULL;
    }
    return ret;
}

int EC_KEY_up_ref(EC_KEY *r)
{
    int i = CRYPTO_add(&r->references, 1, CRYPTO_LOCK_EC);
#ifdef REF_PRINT
    REF_PRINT("EC_KEY", r);
#endif
#ifdef REF_CHECK
    if (i < 2) {
        fprintf(stderr, "EC_KEY_up, bad reference count\n");
        abort();
    }
#endif
    return ((i > 1) ? 1 : 0);
}

int EC_KEY_generate_key(EC_KEY *eckey)
{
    if (eckey == NULL || eckey->group == NULL) {
        ECerr(EC_F_EC_KEY_GENERATE_KEY, ERR_R_PASSED_NULL_PARAMETER);
        return 0;
    }
    if (eckey->meth->keygen != NULL)
        return eckey->meth->keygen(eckey);
    ECerr(EC_F_EC_KEY_GENERATE_KEY, EC_R_OPERATION_NOT_SUPPORTED);
    return 0;
}

int ossl_ec_key_gen(EC_KEY *eckey)
{
    int ok = 0;
    BN_CTX *ctx = NULL;
    BIGNUM *priv_key = NULL, *order = NULL;
    EC_POINT *pub_key = NULL;

    if ((order = BN_new()) == NULL)
        goto err;
    if ((ctx = BN_CTX_new()) == NULL)
        goto err;

    if (eckey->priv_key == NULL) {
        priv_key = BN_new();
        if (priv_key == NULL)
            goto err;
    } else
        priv_key = eckey->priv_key;

    if (!EC_GROUP_get_order(eckey->group, order, ctx))
        goto err;

    do
        if (!BN_rand_range(priv_key, order))
            goto err;
    while (BN_is_zero(priv_key)) ;

    if (eckey->pub_key == NULL) {
        pub_key = EC_POINT_new(eckey->group);
        if (pub_key == NULL)
            goto err;
    } else
        pub_key = eckey->pub_key;

    if (!EC_POINT_mul(eckey->group, pub_key, priv_key, NULL, NULL, ctx))
        goto err;

    eckey->priv_key = priv_key;
    eckey->pub_key = pub_key;

    ok = 1;

 err:
    BN_free(order);
    if (eckey->pub_key == NULL)
        EC_POINT_free(pub_key);
    if (eckey->priv_key != priv_key)
        BN_free(priv_key);
    BN_CTX_free(ctx);
    return (ok);
}

int EC_KEY_check_key(const EC_KEY *eckey)
{
    int ok = 0;
    BN_CTX *ctx = NULL;
    const BIGNUM *order = NULL;
    EC_POINT *point = NULL;

    if (eckey == NULL || eckey->group == NULL || eckey->pub_key == NULL) {
        ECerr(EC_F_EC_KEY_CHECK_KEY, ERR_R_PASSED_NULL_PARAMETER);
        return 0;
    }

    if (EC_POINT_is_at_infinity(eckey->group, eckey->pub_key)) {
        ECerr(EC_F_EC_KEY_CHECK_KEY, EC_R_POINT_AT_INFINITY);
        goto err;
    }

    if ((ctx = BN_CTX_new()) == NULL)
        goto err;
    if ((point = EC_POINT_new(eckey->group)) == NULL)
        goto err;

    /* testing whether the pub_key is on the elliptic curve */
    if (EC_POINT_is_on_curve(eckey->group, eckey->pub_key, ctx) <= 0) {
        ECerr(EC_F_EC_KEY_CHECK_KEY, EC_R_POINT_IS_NOT_ON_CURVE);
        goto err;
    }
    /* testing whether pub_key * order is the point at infinity */
    order = eckey->group->order;
    if (BN_is_zero(order)) {
        ECerr(EC_F_EC_KEY_CHECK_KEY, EC_R_INVALID_GROUP_ORDER);
        goto err;
    }
    if (!EC_POINT_mul(eckey->group, point, NULL, eckey->pub_key, order, ctx)) {
        ECerr(EC_F_EC_KEY_CHECK_KEY, ERR_R_EC_LIB);
        goto err;
    }
    if (!EC_POINT_is_at_infinity(eckey->group, point)) {
        ECerr(EC_F_EC_KEY_CHECK_KEY, EC_R_WRONG_ORDER);
        goto err;
    }
    /*
     * in case the priv_key is present : check if generator * priv_key ==
     * pub_key
     */
    if (eckey->priv_key != NULL) {
        if (BN_cmp(eckey->priv_key, order) >= 0) {
            ECerr(EC_F_EC_KEY_CHECK_KEY, EC_R_WRONG_ORDER);
            goto err;
        }
        if (!EC_POINT_mul(eckey->group, point, eckey->priv_key,
                          NULL, NULL, ctx)) {
            ECerr(EC_F_EC_KEY_CHECK_KEY, ERR_R_EC_LIB);
            goto err;
        }
        if (EC_POINT_cmp(eckey->group, point, eckey->pub_key, ctx) != 0) {
            ECerr(EC_F_EC_KEY_CHECK_KEY, EC_R_INVALID_PRIVATE_KEY);
            goto err;
        }
    }
    ok = 1;
 err:
    BN_CTX_free(ctx);
    EC_POINT_free(point);
    return (ok);
}

int EC_KEY_set_public_key_affine_coordinates(EC_KEY *key, BIGNUM *x,
                                             BIGNUM *y)
{
    BN_CTX *ctx = NULL;
    BIGNUM *tx, *ty;
    EC_POINT *point = NULL;
    int ok = 0;
#ifndef OPENSSL_NO_EC2M
    int tmp_nid, is_char_two = 0;
#endif

    if (key == NULL || key->group == NULL || x == NULL || y == NULL) {
        ECerr(EC_F_EC_KEY_SET_PUBLIC_KEY_AFFINE_COORDINATES,
              ERR_R_PASSED_NULL_PARAMETER);
        return 0;
    }
    ctx = BN_CTX_new();
    if (ctx == NULL)
        goto err;

    point = EC_POINT_new(key->group);

    if (point == NULL)
        goto err;

    tx = BN_CTX_get(ctx);
    ty = BN_CTX_get(ctx);
    if (ty == NULL)
        goto err;

#ifndef OPENSSL_NO_EC2M
    tmp_nid = EC_METHOD_get_field_type(EC_GROUP_method_of(key->group));

    if (tmp_nid == NID_X9_62_characteristic_two_field)
        is_char_two = 1;

    if (is_char_two) {
        if (!EC_POINT_set_affine_coordinates_GF2m(key->group, point,
                                                  x, y, ctx))
            goto err;
        if (!EC_POINT_get_affine_coordinates_GF2m(key->group, point,
                                                  tx, ty, ctx))
            goto err;
    } else
#endif
    {
        if (!EC_POINT_set_affine_coordinates_GFp(key->group, point,
                                                 x, y, ctx))
            goto err;
        if (!EC_POINT_get_affine_coordinates_GFp(key->group, point,
                                                 tx, ty, ctx))
            goto err;
    }
    /*
     * Check if retrieved coordinates match originals and are less than field
     * order: if not values are out of range.
     */
    if (BN_cmp(x, tx) || BN_cmp(y, ty)
        || (BN_cmp(x, key->group->field) >= 0)
        || (BN_cmp(y, key->group->field) >= 0)) {
        ECerr(EC_F_EC_KEY_SET_PUBLIC_KEY_AFFINE_COORDINATES,
              EC_R_COORDINATES_OUT_OF_RANGE);
        goto err;
    }

    if (!EC_KEY_set_public_key(key, point))
        goto err;

    if (EC_KEY_check_key(key) == 0)
        goto err;

    ok = 1;

 err:
    BN_CTX_free(ctx);
    EC_POINT_free(point);
    return ok;

}

const EC_GROUP *EC_KEY_get0_group(const EC_KEY *key)
{
    return key->group;
}

int EC_KEY_set_group(EC_KEY *key, const EC_GROUP *group)
{
    if (key->meth->set_group != NULL && key->meth->set_group(key, group) == 0)
        return 0;
    EC_GROUP_free(key->group);
    key->group = EC_GROUP_dup(group);
    return (key->group == NULL) ? 0 : 1;
}

const BIGNUM *EC_KEY_get0_private_key(const EC_KEY *key)
{
    return key->priv_key;
}

int EC_KEY_set_private_key(EC_KEY *key, const BIGNUM *priv_key)
{
    if (key->meth->set_private != NULL
        && key->meth->set_private(key, priv_key) == 0)
        return 0;
    BN_clear_free(key->priv_key);
    key->priv_key = BN_dup(priv_key);
    return (key->priv_key == NULL) ? 0 : 1;
}

const EC_POINT *EC_KEY_get0_public_key(const EC_KEY *key)
{
    return key->pub_key;
}

int EC_KEY_set_public_key(EC_KEY *key, const EC_POINT *pub_key)
{
    if (key->meth->set_public != NULL
        && key->meth->set_public(key, pub_key) == 0)
        return 0;
    EC_POINT_free(key->pub_key);
    key->pub_key = EC_POINT_dup(pub_key, key->group);
    return (key->pub_key == NULL) ? 0 : 1;
}

unsigned int EC_KEY_get_enc_flags(const EC_KEY *key)
{
    return key->enc_flag;
}

void EC_KEY_set_enc_flags(EC_KEY *key, unsigned int flags)
{
    key->enc_flag = flags;
}

point_conversion_form_t EC_KEY_get_conv_form(const EC_KEY *key)
{
    return key->conv_form;
}

void EC_KEY_set_conv_form(EC_KEY *key, point_conversion_form_t cform)
{
    key->conv_form = cform;
    if (key->group != NULL)
        EC_GROUP_set_point_conversion_form(key->group, cform);
}

void EC_KEY_set_asn1_flag(EC_KEY *key, int flag)
{
    if (key->group != NULL)
        EC_GROUP_set_asn1_flag(key->group, flag);
}

int EC_KEY_precompute_mult(EC_KEY *key, BN_CTX *ctx)
{
    if (key->group == NULL)
        return 0;
    return EC_GROUP_precompute_mult(key->group, ctx);
}

int EC_KEY_get_flags(const EC_KEY *key)
{
    return key->flags;
}

void EC_KEY_set_flags(EC_KEY *key, int flags)
{
    key->flags |= flags;
}

void EC_KEY_clear_flags(EC_KEY *key, int flags)
{
    key->flags &= ~flags;
}

size_t EC_KEY_key2buf(const EC_KEY *key, point_conversion_form_t form,
                        unsigned char **pbuf, BN_CTX *ctx)
{
    if (key == NULL || key->pub_key == NULL || key->group == NULL)
        return 0;
    return EC_POINT_point2buf(key->group, key->pub_key, form, pbuf, ctx);
}

int EC_KEY_oct2key(EC_KEY *key, const unsigned char *buf, size_t len,
                   BN_CTX *ctx)
{
    if (key == NULL || key->group == NULL)
        return 0;
    if (key->pub_key == NULL)
        key->pub_key = EC_POINT_new(key->group);
    if (key->pub_key == NULL)
        return 0;
    return EC_POINT_oct2point(key->group, key->pub_key, buf, len, ctx);
}
