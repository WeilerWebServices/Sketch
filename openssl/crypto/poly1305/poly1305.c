/* ====================================================================
 * Copyright (c) 2015 The OpenSSL Project. All rights reserved.
 *
 * Rights for redistribution and usage in source and binary
 * forms are granted according to the OpenSSL license.
 */

#include <stdlib.h>
#include <string.h>

#include "internal/poly1305.h"

typedef void (*poly1305_blocks_f) (void *ctx, const unsigned char *inp,
                                   size_t len, unsigned int padbit);
typedef void (*poly1305_emit_f) (void *ctx, unsigned char mac[16],
                                 const unsigned int nonce[4]);

struct poly1305_context {
    double opaque[24];  /* large enough to hold internal state, declared
                         * 'double' to ensure at least 64-bit invariant
                         * alignment across all platforms and
                         * configurations */
    unsigned int nonce[4];
    unsigned char data[POLY1305_BLOCK_SIZE];
    size_t num;
    struct {
        poly1305_blocks_f blocks;
        poly1305_emit_f emit;
    } func;
};

size_t Poly1305_ctx_size ()
{
    return sizeof(struct poly1305_context);
}

/* pick 32-bit unsigned integer in little endian order */
static unsigned int U8TOU32(const unsigned char *p)
{
    return (((unsigned int)(p[0] & 0xff)) |
            ((unsigned int)(p[1] & 0xff) << 8) |
            ((unsigned int)(p[2] & 0xff) << 16) |
            ((unsigned int)(p[3] & 0xff) << 24));
}

/*
 * Implementations can be classified by amount of significant bits in
 * words making up the multi-precision value, or in other words radix
 * or base of numerical representation, e.g. base 2^64, base 2^32,
 * base 2^26. Complementary characteristic is how wide is the result of
 * multiplication of pair of digits, e.g. it would take 128 bits to
 * accommodate multiplication result in base 2^64 case. These are used
 * interchangeably. To describe implementation that is. But interface
 * is designed to isolate this so that low-level primitives implemented
 * in assembly can be self-contained/self-coherent.
 */
#ifndef POLY1305_ASM
/*
 * Even though there is __int128 reference implementation targeting
 * 64-bit platforms provided below, it's not obvious that it's optimal
 * choice for every one of them. Depending on instruction set overall
 * amount of instructions can be comparable to one in __int64
 * implementation. Amount of multiplication instructions would be lower,
 * but not necessarily overall. And in out-of-order execution context,
 * it is the latter that can be crucial...
 *
 * On related note. Poly1305 author, D. J. Bernstein, discusses and
 * provides floating-point implementations of the algorithm in question.
 * It made a lot of sense by the time of introduction, because most
 * then-modern processors didn't have pipelined integer multiplier.
 * [Not to mention that some had non-constant timing for integer
 * multiplications.] Floating-point instructions on the other hand could
 * be issued every cycle, which allowed to achieve better performance.
 * Nowadays, with SIMD and/or out-or-order execution, shared or
 * even emulated FPU, it's more complicated, and floating-point
 * implementation is not necessarily optimal choice in every situation,
 * rather contrary...
 *
 *                                              <appro@openssl.org>
 */

typedef unsigned int u32;

/*
 * poly1305_blocks processes a multiple of POLY1305_BLOCK_SIZE blocks
 * of |inp| no longer than |len|. Behaviour for |len| not divisible by
 * block size is unspecified in general case, even though in reference
 * implementation the trailing chunk is simply ignored. Per algorithm
 * specification, every input block, complete or last partial, is to be
 * padded with a bit past most significant byte. The latter kind is then
 * padded with zeros till block size. This last partial block padding
 * is caller(*)'s responsibility, and because of this the last partial
 * block is always processed with separate call with |len| set to
 * POLY1305_BLOCK_SIZE and |padbit| to 0. In all other cases |padbit|
 * should be set to 1 to perform implicit padding with 128th bit.
 * poly1305_blocks does not actually check for this constraint though,
 * it's caller(*)'s resposibility to comply.
 *
 * (*)  In the context "caller" is not application code, but higher
 *      level Poly1305_* from this very module, so that quirks are
 *      handled locally.
 */
static void
poly1305_blocks(void *ctx, const unsigned char *inp, size_t len, u32 padbit);

/*
 * Type-agnostic "rip-off" from constant_time_locl.h
 */
# define CONSTANT_TIME_CARRY(a,b) ( \
         (a ^ ((a ^ b) | ((a - b) ^ b))) >> (sizeof(a) * 8 - 1) \
         )

# if !defined(PEDANTIC) && \
     (defined(__SIZEOF_INT128__) && __SIZEOF_INT128__==16) && \
     (defined(__SIZEOF_LONG__) && __SIZEOF_LONG__==8)

typedef unsigned long u64;
typedef unsigned __int128 u128;

typedef struct {
    u64 h[3];
    u64 r[2];
} poly1305_internal;

/* pick 32-bit unsigned integer in little endian order */
static u64 U8TOU64(const unsigned char *p)
{
    return (((u64)(p[0] & 0xff)) |
            ((u64)(p[1] & 0xff) << 8) |
            ((u64)(p[2] & 0xff) << 16) |
            ((u64)(p[3] & 0xff) << 24) |
            ((u64)(p[4] & 0xff) << 32) |
            ((u64)(p[5] & 0xff) << 40) |
            ((u64)(p[6] & 0xff) << 48) |
            ((u64)(p[7] & 0xff) << 56));
}

/* store a 32-bit unsigned integer in little endian */
static void U64TO8(unsigned char *p, u64 v)
{
    p[0] = (unsigned char)((v) & 0xff);
    p[1] = (unsigned char)((v >> 8) & 0xff);
    p[2] = (unsigned char)((v >> 16) & 0xff);
    p[3] = (unsigned char)((v >> 24) & 0xff);
    p[4] = (unsigned char)((v >> 32) & 0xff);
    p[5] = (unsigned char)((v >> 40) & 0xff);
    p[6] = (unsigned char)((v >> 48) & 0xff);
    p[7] = (unsigned char)((v >> 56) & 0xff);
}

static void poly1305_init(void *ctx, const unsigned char key[16])
{
    poly1305_internal *st = (poly1305_internal *) ctx;

    /* h = 0 */
    st->h[0] = 0;
    st->h[1] = 0;
    st->h[2] = 0;

    /* r &= 0xffffffc0ffffffc0ffffffc0fffffff */
    st->r[0] = U8TOU64(&key[0]) & 0x0ffffffc0fffffff;
    st->r[1] = U8TOU64(&key[8]) & 0x0ffffffc0ffffffc;
}

static void
poly1305_blocks(void *ctx, const unsigned char *inp, size_t len, u32 padbit)
{
    poly1305_internal *st = (poly1305_internal *)ctx;
    u64 r0, r1;
    u64 s1;
    u64 h0, h1, h2, c;
    u128 d0, d1;

    r0 = st->r[0];
    r1 = st->r[1];

    s1 = r1 + (r1 >> 2);

    h0 = st->h[0];
    h1 = st->h[1];
    h2 = st->h[2];

    while (len >= POLY1305_BLOCK_SIZE) {
        /* h += m[i] */
        h0 = (u64)(d0 = (u128)h0 + U8TOU64(inp + 0));
        h1 = (u64)(d1 = (u128)h1 + (d0 >> 64) + U8TOU64(inp + 8));
        /*
	 * padbit can be zero only when original len was
	 * POLY1306_BLOCK_SIZE, but we don't check
	 */
        h2 += (u64)(d1 >> 64) + padbit;

        /* h *= r "%" p, where "%" stands for "partial remainder" */
        d0 = ((u128)h0 * r0) +
             ((u128)h1 * s1);
        d1 = ((u128)h0 * r1) +
             ((u128)h1 * r0) +
	     (h2 * s1);
        h2 = (h2 * r0);

        /* last reduction step: */
        /* a) h2:h0 = h2<<128 + d1<<64 + d0 */
        h0 = (u64)d0;
        h1 = (u64)(d1 += d0 >> 64);
        h2 += (u64)(d1 >> 64);
        /* b) (h2:h0 += (h2:h0>>130) * 5) %= 2^130 */
        c = (h2 >> 2) + (h2 & ~3UL);
        h2 &= 3;
        h0 += c;
        h1 += (c = CONSTANT_TIME_CARRY(h0,c));   /* doesn't overflow */

        inp += POLY1305_BLOCK_SIZE;
        len -= POLY1305_BLOCK_SIZE;
    }

    st->h[0] = h0;
    st->h[1] = h1;
    st->h[2] = h2;
}

static void poly1305_emit(void *ctx, unsigned char mac[16],
                          const u32 nonce[4])
{
    poly1305_internal *st = (poly1305_internal *) ctx;
    u64 h0, h1, h2;
    u64 g0, g1, g2;
    u128 t;
    u64 mask;

    h0 = st->h[0];
    h1 = st->h[1];
    h2 = st->h[2];

    /* compute h + -p */
    g0 = (u64)(t = (u128)h0 + 5);
    g1 = (u64)(t = (u128)h1 + (t >> 64));
    g2 = h2 + (u64)(t >> 64);

    /* if there was carry into 130th bit, h1:h0 = g1:g0 */
    mask = 0 - (g2 >> 2);
    g0 &= mask;
    g1 &= mask;
    mask = ~mask;
    h0 = (h0 & mask) | g0;
    h1 = (h1 & mask) | g1;

    /* mac = (h + nonce) % (2^128) */
    h0 = (u64)(t = (u128)h0 + nonce[0] + ((u64)nonce[1]<<32));
    h1 = (u64)(t = (u128)h1 + nonce[2] + ((u64)nonce[3]<<32) + (t >> 64));

    U64TO8(mac + 0, h0);
    U64TO8(mac + 8, h1);
}

# else

#  if defined(_WIN32) && !defined(__MINGW32__)
typedef unsigned __int64 u64;
#  elif defined(__arch64__)
typedef unsigned long u64;
#  else
typedef unsigned long long u64;
#  endif

typedef struct {
    u32 h[5];
    u32 r[4];
} poly1305_internal;

/* store a 32-bit unsigned integer in little endian */
static void U32TO8(unsigned char *p, unsigned int v)
{
    p[0] = (unsigned char)((v) & 0xff);
    p[1] = (unsigned char)((v >> 8) & 0xff);
    p[2] = (unsigned char)((v >> 16) & 0xff);
    p[3] = (unsigned char)((v >> 24) & 0xff);
}

static void poly1305_init(void *ctx, const unsigned char key[16])
{
    poly1305_internal *st = (poly1305_internal *) ctx;

    /* h = 0 */
    st->h[0] = 0;
    st->h[1] = 0;
    st->h[2] = 0;
    st->h[3] = 0;
    st->h[4] = 0;

    /* r &= 0xffffffc0ffffffc0ffffffc0fffffff */
    st->r[0] = U8TOU32(&key[0]) & 0x0fffffff;
    st->r[1] = U8TOU32(&key[4]) & 0x0ffffffc;
    st->r[2] = U8TOU32(&key[8]) & 0x0ffffffc;
    st->r[3] = U8TOU32(&key[12]) & 0x0ffffffc;
}

static void
poly1305_blocks(void *ctx, const unsigned char *inp, size_t len, u32 padbit)
{
    poly1305_internal *st = (poly1305_internal *)ctx;
    u32 r0, r1, r2, r3;
    u32 s1, s2, s3;
    u32 h0, h1, h2, h3, h4, c;
    u64 d0, d1, d2, d3;

    r0 = st->r[0];
    r1 = st->r[1];
    r2 = st->r[2];
    r3 = st->r[3];

    s1 = r1 + (r1 >> 2);
    s2 = r2 + (r2 >> 2);
    s3 = r3 + (r3 >> 2);

    h0 = st->h[0];
    h1 = st->h[1];
    h2 = st->h[2];
    h3 = st->h[3];
    h4 = st->h[4];

    while (len >= POLY1305_BLOCK_SIZE) {
        /* h += m[i] */
        h0 = (u32)(d0 = (u64)h0 + U8TOU32(inp + 0));
        h1 = (u32)(d1 = (u64)h1 + (d0 >> 32) + U8TOU32(inp + 4));
        h2 = (u32)(d2 = (u64)h2 + (d1 >> 32) + U8TOU32(inp + 8));
        h3 = (u32)(d3 = (u64)h3 + (d2 >> 32) + U8TOU32(inp + 12));
        h4 += (u32)(d3 >> 32) + padbit;

        /* h *= r "%" p, where "%" stands for "partial remainder" */
        d0 = ((u64)h0 * r0) +
             ((u64)h1 * s3) +
             ((u64)h2 * s2) +
             ((u64)h3 * s1);
        d1 = ((u64)h0 * r1) +
             ((u64)h1 * r0) +
             ((u64)h2 * s3) +
             ((u64)h3 * s2) +
             (h4 * s1);
        d2 = ((u64)h0 * r2) +
             ((u64)h1 * r1) +
             ((u64)h2 * r0) +
             ((u64)h3 * s3) +
             (h4 * s2);
        d3 = ((u64)h0 * r3) +
             ((u64)h1 * r2) +
             ((u64)h2 * r1) +
             ((u64)h3 * r0) +
             (h4 * s3);
        h4 = (h4 * r0);

        /* last reduction step: */
        /* a) h4:h0 = h4<<128 + d3<<96 + d2<<64 + d1<<32 + d0 */
        h0 = (u32)d0;
        h1 = (u32)(d1 += d0 >> 32);
        h2 = (u32)(d2 += d1 >> 32);
        h3 = (u32)(d3 += d2 >> 32);
        h4 += (u32)(d3 >> 32);
        /* b) (h4:h0 += (h4:h0>>130) * 5) %= 2^130 */
        c = (h4 >> 2) + (h4 & ~3U);
        h4 &= 3;
        h0 += c;
        h1 += (c = CONSTANT_TIME_CARRY(h0,c));
        h2 += (c = CONSTANT_TIME_CARRY(h1,c));
        h3 += (c = CONSTANT_TIME_CARRY(h2,c));   /* doesn't overflow */

        inp += POLY1305_BLOCK_SIZE;
        len -= POLY1305_BLOCK_SIZE;
    }

    st->h[0] = h0;
    st->h[1] = h1;
    st->h[2] = h2;
    st->h[3] = h3;
    st->h[4] = h4;
}

static void poly1305_emit(void *ctx, unsigned char mac[16],
                          const u32 nonce[4])
{
    poly1305_internal *st = (poly1305_internal *) ctx;
    u32 h0, h1, h2, h3, h4;
    u32 g0, g1, g2, g3, g4;
    u64 t;
    u32 mask;

    h0 = st->h[0];
    h1 = st->h[1];
    h2 = st->h[2];
    h3 = st->h[3];
    h4 = st->h[4];

    /* compute h + -p */
    g0 = (u32)(t = (u64)h0 + 5);
    g1 = (u32)(t = (u64)h1 + (t >> 32));
    g2 = (u32)(t = (u64)h2 + (t >> 32));
    g3 = (u32)(t = (u64)h3 + (t >> 32));
    g4 = h4 + (u32)(t >> 32);

    /* if there was carry into 130th bit, h3:h0 = g3:g0 */
    mask = 0 - (g4 >> 2);
    g0 &= mask;
    g1 &= mask;
    g2 &= mask;
    g3 &= mask;
    mask = ~mask;
    h0 = (h0 & mask) | g0;
    h1 = (h1 & mask) | g1;
    h2 = (h2 & mask) | g2;
    h3 = (h3 & mask) | g3;

    /* mac = (h + nonce) % (2^128) */
    h0 = (u32)(t = (u64)h0 + nonce[0]);
    h1 = (u32)(t = (u64)h1 + (t >> 32) + nonce[1]);
    h2 = (u32)(t = (u64)h2 + (t >> 32) + nonce[2]);
    h3 = (u32)(t = (u64)h3 + (t >> 32) + nonce[3]);

    U32TO8(mac + 0, h0);
    U32TO8(mac + 4, h1);
    U32TO8(mac + 8, h2);
    U32TO8(mac + 12, h3);
}
# endif
#else
int poly1305_init(void *ctx, const unsigned char key[16], void *func);
void poly1305_blocks(void *ctx, const unsigned char *inp, size_t len,
                     unsigned int padbit);
void poly1305_emit(void *ctx, unsigned char mac[16],
                   const unsigned int nonce[4]);
#endif

void Poly1305_Init(POLY1305 *ctx, const unsigned char key[32])
{
    ctx->nonce[0] = U8TOU32(&key[16]);
    ctx->nonce[1] = U8TOU32(&key[20]);
    ctx->nonce[2] = U8TOU32(&key[24]);
    ctx->nonce[3] = U8TOU32(&key[28]);

#ifndef POLY1305_ASM
    poly1305_init(ctx->opaque, key);
#else
    /*
     * Unlike reference poly1305_init assembly counterpart is expected
     * to return a value: non-zero if it initializes ctx->func, and zero
     * otherwise. Latter is to simplify assembly in cases when there no
     * multiple code paths to switch between.
     */
    if (!poly1305_init(ctx->opaque, key, &ctx->func)) {
        ctx->func.blocks = poly1305_blocks;
        ctx->func.emit = poly1305_emit;
    }
#endif

    ctx->num = 0;

}

void Poly1305_Update(POLY1305 *ctx, const unsigned char *inp, size_t len)
{
#ifdef POLY1305_ASM
    /*
     * As documented, poly1305_blocks is never called with input
     * longer than single block and padbit argument set to 0. This
     * property is fluently used in assembly modules to optimize
     * padbit handling on loop boundary.
     */
    poly1305_blocks_f poly1305_blocks = ctx->func.blocks;
#endif
    size_t rem, num;

    if ((num = ctx->num)) {
        rem = POLY1305_BLOCK_SIZE - num;
        if (len >= rem) {
            memcpy(ctx->data + num, inp, rem);
            poly1305_blocks(ctx->opaque, ctx->data, POLY1305_BLOCK_SIZE, 1);
            inp += rem;
            len -= rem;
        } else {
            /* Still not enough data to process a block. */
            memcpy(ctx->data + num, inp, len);
            ctx->num = num + len;
            return;
        }
    }

    rem = len % POLY1305_BLOCK_SIZE;
    len -= rem;

    if (len >= POLY1305_BLOCK_SIZE) {
        poly1305_blocks(ctx->opaque, inp, len, 1);
        inp += len;
    }

    if (rem)
        memcpy(ctx->data, inp, rem);

    ctx->num = rem;
}

void Poly1305_Final(POLY1305 *ctx, unsigned char mac[16])
{
#ifdef POLY1305_ASM
    poly1305_blocks_f poly1305_blocks = ctx->func.blocks;
    poly1305_emit_f poly1305_emit = ctx->func.emit;
#endif
    size_t num;

    if ((num = ctx->num)) {
        ctx->data[num++] = 1;   /* pad bit */
        while (num < POLY1305_BLOCK_SIZE)
            ctx->data[num++] = 0;
        poly1305_blocks(ctx->opaque, ctx->data, POLY1305_BLOCK_SIZE, 0);
    }

    poly1305_emit(ctx->opaque, mac, ctx->nonce);

    /* zero out the state */
    memset(ctx, 0, sizeof(*ctx));
}

#ifdef SELFTEST
#include <stdio.h>

struct poly1305_test {
    const char *inputhex;
    const char *keyhex;
    const char *outhex;
};

static const struct poly1305_test poly1305_tests[] = {
    /*
     * RFC7539
     */
    {
     "43727970746f6772617068696320466f72756d2052657365617263682047726f"
     "7570",
     "85d6be7857556d337f4452fe42d506a8""0103808afb0db2fd4abff6af4149f51b",
     "a8061dc1305136c6c22b8baf0c0127a9"
    },
    /*
     * test vectors from "The Poly1305-AES message-authentication code"
     */
    {
     "f3f6",
     "851fc40c3467ac0be05cc20404f3f700""580b3b0f9447bb1e69d095b5928b6dbc",
     "f4c633c3044fc145f84f335cb81953de"
    },
    {
     "",
     "a0f3080000f46400d0c7e9076c834403""dd3fab2251f11ac759f0887129cc2ee7",
     "dd3fab2251f11ac759f0887129cc2ee7"
    },
    {
     "663cea190ffb83d89593f3f476b6bc24d7e679107ea26adb8caf6652d0656136",
     "48443d0bb0d21109c89a100b5ce2c208""83149c69b561dd88298a1798b10716ef",
     "0ee1c16bb73f0f4fd19881753c01cdbe"
    },
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "5154ad0d2cb26e01274fc51148491f1b"
    },
    /*
     * self-generated
     */
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "812059a5da198637cac7c4a631bee466"
    },
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "5b88d7f6228b11e2e28579a5c0c1f761"
    },
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af"
     "663cea190ffb83d89593f3f476b6bc24d7e679107ea26adb8caf6652d0656136",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "bbb613b2b6d753ba07395b916aaece15"
    },
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af"
     "48443d0bb0d21109c89a100b5ce2c20883149c69b561dd88298a1798b10716ef"
     "663cea190ffb83d89593f3f476b6bc24",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "c794d7057d1778c4bbee0a39b3d97342"
    },
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af"
     "48443d0bb0d21109c89a100b5ce2c20883149c69b561dd88298a1798b10716ef"
     "663cea190ffb83d89593f3f476b6bc24d7e679107ea26adb8caf6652d0656136",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "ffbcb9b371423152d7fca5ad042fbaa9"
    },
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af"
     "48443d0bb0d21109c89a100b5ce2c20883149c69b561dd88298a1798b10716ef"
     "663cea190ffb83d89593f3f476b6bc24d7e679107ea26adb8caf6652d0656136"
     "812059a5da198637cac7c4a631bee466",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "069ed6b8ef0f207b3e243bb1019fe632"
    },
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af"
     "48443d0bb0d21109c89a100b5ce2c20883149c69b561dd88298a1798b10716ef"
     "663cea190ffb83d89593f3f476b6bc24d7e679107ea26adb8caf6652d0656136"
     "812059a5da198637cac7c4a631bee4665b88d7f6228b11e2e28579a5c0c1f761",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "cca339d9a45fa2368c2c68b3a4179133"
    },
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af"
     "48443d0bb0d21109c89a100b5ce2c20883149c69b561dd88298a1798b10716ef"
     "663cea190ffb83d89593f3f476b6bc24d7e679107ea26adb8caf6652d0656136"
     "812059a5da198637cac7c4a631bee4665b88d7f6228b11e2e28579a5c0c1f761"
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af"
     "48443d0bb0d21109c89a100b5ce2c20883149c69b561dd88298a1798b10716ef"
     "663cea190ffb83d89593f3f476b6bc24d7e679107ea26adb8caf6652d0656136",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "53f6e828a2f0fe0ee815bf0bd5841a34"
    },
    {
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af"
     "48443d0bb0d21109c89a100b5ce2c20883149c69b561dd88298a1798b10716ef"
     "663cea190ffb83d89593f3f476b6bc24d7e679107ea26adb8caf6652d0656136"
     "812059a5da198637cac7c4a631bee4665b88d7f6228b11e2e28579a5c0c1f761"
     "ab0812724a7f1e342742cbed374d94d136c6b8795d45b3819830f2c04491faf0"
     "990c62e48b8018b2c3e4a0fa3134cb67fa83e158c994d961c4cb21095c1bf9af"
     "48443d0bb0d21109c89a100b5ce2c20883149c69b561dd88298a1798b10716ef"
     "663cea190ffb83d89593f3f476b6bc24d7e679107ea26adb8caf6652d0656136"
     "812059a5da198637cac7c4a631bee4665b88d7f6228b11e2e28579a5c0c1f761",
     "12976a08c4426d0ce8a82407c4f48207""80f8c20aa71202d1e29179cbcb555a57",
     "b846d44e9bbd53cedffbfbb6b7fa4933"
    },
    {
    /*
     * poly1305_ieee754.c failed this in final stage
     */
     "842364e156336c0998b933a6237726180d9e3fdcbde4cd5d17080fc3beb49614"
     "d7122c037463ff104d73f19c12704628d417c4c54a3fe30d3c3d7714382d43b0"
     "382a50a5dee54be844b076e8df88201a1cd43b90eb21643fa96f39b518aa8340"
     "c942ff3c31baf7c9bdbf0f31ae3fa096bf8c63030609829fe72e179824890bc8"
     "e08c315c1cce2a83144dbbff09f74e3efc770b54d0984a8f19b14719e6363564"
     "1d6b1eedf63efbf080e1783d32445412114c20de0b837a0dfa33d6b82825fff4"
     "4c9a70ea54ce47f07df698e6b03323b53079364a5fc3e9dd034392bdde86dccd"
     "da94321c5e44060489336cb65bf3989c36f7282c2f5d2b882c171e74",
     "95d5c005503e510d8cd0aa072c4a4d06""6eabc52d11653df47fbf63ab198bcc26",
     "f248312e578d9d58f8b7bb4d19105431"
    },
    /*
     * test vectors from Google
     */
    {
     "",
     "c8afaac331ee372cd6082de134943b17""4710130e9f6fea8d72293850a667d86c",
     "4710130e9f6fea8d72293850a667d86c",
    },
    {
     "48656c6c6f20776f726c6421",
     "746869732069732033322d6279746520""6b657920666f7220506f6c7931333035",
     "a6f745008f81c916a20dcc74eef2b2f0"
    },
    {
     "0000000000000000000000000000000000000000000000000000000000000000",
     "746869732069732033322d6279746520""6b657920666f7220506f6c7931333035",
     "49ec78090e481ec6c26b33b91ccc0307"
    },
    /*
     * test vectors from Andrew Moon
     */
    {   /* nacl */
     "8e993b9f48681273c29650ba32fc76ce48332ea7164d96a4476fb8c531a1186a"
     "c0dfc17c98dce87b4da7f011ec48c97271d2c20f9b928fe2270d6fb863d51738"
     "b48eeee314a7cc8ab932164548e526ae90224368517acfeabd6bb3732bc0e9da"
     "99832b61ca01b6de56244a9e88d5f9b37973f622a43d14a6599b1f654cb45a74"
     "e355a5",
     "eea6a7251c1e72916d11c2cb214d3c25""2539121d8e234e652d651fa4c8cff880",
     "f3ffc7703f9400e52a7dfb4b3d3305d9"
    },
    {   /* wrap 2^130-5 */
     "ffffffffffffffffffffffffffffffff",
     "02000000000000000000000000000000""00000000000000000000000000000000",
     "03000000000000000000000000000000"
    },
    {   /* wrap 2^128 */
     "02000000000000000000000000000000",
     "02000000000000000000000000000000""ffffffffffffffffffffffffffffffff",
     "03000000000000000000000000000000"
    },
    {   /* limb carry */
     "fffffffffffffffffffffffffffffffff0ffffffffffffffffffffffffffffff"
     "11000000000000000000000000000000",
     "01000000000000000000000000000000""00000000000000000000000000000000",
     "05000000000000000000000000000000"
    },
    {   /* 2^130-5 */
     "fffffffffffffffffffffffffffffffffbfefefefefefefefefefefefefefefe"
     "01010101010101010101010101010101",
     "01000000000000000000000000000000""00000000000000000000000000000000",
     "00000000000000000000000000000000"
    },
    {   /* 2^130-6 */
     "fdffffffffffffffffffffffffffffff",
     "02000000000000000000000000000000""00000000000000000000000000000000",
     "faffffffffffffffffffffffffffffff"
    },
    {   /* 5*H+L reduction intermediate */
     "e33594d7505e43b900000000000000003394d7505e4379cd0100000000000000"
     "0000000000000000000000000000000001000000000000000000000000000000",
     "01000000000000000400000000000000""00000000000000000000000000000000",
     "14000000000000005500000000000000"
    },
    {   /* 5*H+L reduction final */
     "e33594d7505e43b900000000000000003394d7505e4379cd0100000000000000"
     "00000000000000000000000000000000",
     "01000000000000000400000000000000""00000000000000000000000000000000",
     "13000000000000000000000000000000"
    }
};

static unsigned char hex_digit(char h)
{
    if (h >= '0' && h <= '9')
        return h - '0';
    else if (h >= 'a' && h <= 'f')
        return h - 'a' + 10;
    else if (h >= 'A' && h <= 'F')
        return h - 'A' + 10;
    else
        abort();
}

static void hex_decode(unsigned char *out, const char *hex)
{
    size_t j = 0;

    while (*hex != 0) {
        unsigned char v = hex_digit(*hex++);
        v <<= 4;
        v |= hex_digit(*hex++);
        out[j++] = v;
    }
}

static void hexdump(unsigned char *a, size_t len)
{
    size_t i;

    for (i = 0; i < len; i++)
        printf("%02x", a[i]);
}

int main()
{
    static const unsigned num_tests =
        sizeof(poly1305_tests) / sizeof(struct poly1305_test);
    unsigned i;
    unsigned char key[32], out[16], expected[16];
    POLY1305 poly1305;

    for (i = 0; i < num_tests; i++) {
        const struct poly1305_test *test = &poly1305_tests[i];
        unsigned char *in;
        size_t inlen = strlen(test->inputhex);

        if (strlen(test->keyhex) != sizeof(key) * 2 ||
            strlen(test->outhex) != sizeof(out) * 2 || (inlen & 1) == 1)
            return 1;

        inlen /= 2;

        hex_decode(key, test->keyhex);
        hex_decode(expected, test->outhex);

        in = malloc(inlen);

        hex_decode(in, test->inputhex);

        Poly1305_Init(&poly1305, key);
        Poly1305_Update(&poly1305, in, inlen);
        Poly1305_Final(&poly1305, out);

        if (memcmp(out, expected, sizeof(expected)) != 0) {
            printf("Poly1305 test #%d failed.\n", i);
            printf("got:      ");
            hexdump(out, sizeof(out));
            printf("\nexpected: ");
            hexdump(expected, sizeof(expected));
            printf("\n");
            return 1;
        }

        if (inlen > 16) {
            Poly1305_Init(&poly1305, key);
            Poly1305_Update(&poly1305, in, 1);
            Poly1305_Update(&poly1305, in+1, inlen-1);
            Poly1305_Final(&poly1305, out);

            if (memcmp(out, expected, sizeof(expected)) != 0) {
                printf("Poly1305 test #%d/1+(N-1) failed.\n", i);
                printf("got:      ");
                hexdump(out, sizeof(out));
                printf("\nexpected: ");
                hexdump(expected, sizeof(expected));
                printf("\n");
                return 1;
            }
        }

        if (inlen > 32) {
            size_t half = inlen / 2;

            Poly1305_Init(&poly1305, key);
            Poly1305_Update(&poly1305, in, half);
            Poly1305_Update(&poly1305, in+half, inlen-half);
            Poly1305_Final(&poly1305, out);

            if (memcmp(out, expected, sizeof(expected)) != 0) {
                printf("Poly1305 test #%d/2 failed.\n", i);
                printf("got:      ");
                hexdump(out, sizeof(out));
                printf("\nexpected: ");
                hexdump(expected, sizeof(expected));
                printf("\n");
                return 1;
            }
        }

        free(in);
    }

    printf("PASS\n");

# ifdef OPENSSL_CPUID_OBJ
    {
        unsigned char buf[8192];
        unsigned long long stopwatch;
        unsigned long long OPENSSL_rdtsc();

        memset (buf,0x55,sizeof(buf));
        memset (key,0xAA,sizeof(key));

        Poly1305_Init(&poly1305, key);

        for (i=0;i<100000;i++)
	    Poly1305_Update(&poly1305,buf,sizeof(buf));

	stopwatch = OPENSSL_rdtsc();
        for (i=0;i<10000;i++)
	    Poly1305_Update(&poly1305,buf,sizeof(buf));
	stopwatch = OPENSSL_rdtsc() - stopwatch;

	printf("%g\n",stopwatch/(double)(i*sizeof(buf)));

        stopwatch = OPENSSL_rdtsc();
        for (i=0;i<10000;i++) {
            Poly1305_Init(&poly1305, key);
            Poly1305_Update(&poly1305,buf,16);
            Poly1305_Final(&poly1305,buf);
        }
        stopwatch = OPENSSL_rdtsc() - stopwatch;

        printf("%g\n",stopwatch/(double)(i));
    }
# endif
    return 0;
}
#endif
