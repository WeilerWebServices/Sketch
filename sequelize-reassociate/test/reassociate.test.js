const test = require('ava');
const db = require('./db');
const Reassociate = require('../index');

test.before(async t => {
  // build test db
  await db.sequelize.sync({force: true});  

  // setup sequelize-reassociate
  Reassociate(db.sequelize);
});

test.beforeEach(async t => {
  // setup ghost user
  t.context.ghostUser = await db.models.User.create({name: 'ghost-user'});

  // setup test user with comments
  t.context.testUser1 = await db.models.User.create({
    name: 'Overly Excited Bob', 
    comments: [
      {body: 'amazing!'},
      {body: 'yay'},
    ]
  }, {
    include: [db.models.Comment], 
  });

  t.context.testUser2 = await db.models.User.create({
    name: 'Another User', 
    comments: [
      {body: 'such comment'},
      {body: 'wow'},
    ]
  }, {
    include: [db.models.Comment],
  });

  // and remove the user, should leave comments behind
  await t.context.testUser1.destroy();
});

test('it should move comments to ghost user', async t => {
  const commentIds = t.context.testUser1.comments.map(c => c.get('id'));
  const comments = await db.models.Comment.findAll({where: {id: {$in: commentIds }}});
  const expected = comments.map(c => c.get('userId'));
  t.deepEqual(expected, [1, 1]);
});

test('it should leave owned models as is', async t => {
  const commentIds = t.context.testUser2.comments.map(c => c.get('id'));
  const comments = await db.models.Comment.findAll({where: {id: {$in: commentIds }}});
  const expected = comments.map(c => c.get('userId'));
  t.deepEqual(expected, [t.context.testUser2.get('id'), t.context.testUser2.get('id')]);
});
