RedisObject = require './redis_object'
{generate_identity} = require '../identity'
UserApp = require './user_application'

###*
 * Acts as a base class for all Redis-based objects.
###
class User extends RedisObject
  constructor: ->
    super
    @object_name = 'user'
    @applications = new UserApp(@current)

  ###*
   * Returns the list of user names.
   * @param {Function} (fn) The callback function
  ###
  list: (fn) =>
    return @redis.smembers(''.concat(@prefix(), 's'), fn)

  ###*
   * Returns all of the user objects with the given filter.
   * @param {Object} (filter) The object keys you wish to return (null is all)
   * @param {Function} (fn) The callback function
  ###
  all: (filter=null, fn) =>
    @current = null
    filter = {} unless filter
    @list (err, usernames) =>
      if (filter.name and Object.keys(filter).length is 1) or err
        return fn(err, usernames)

  ###*
   * Searches for the redis objects that match the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) The callback function
  ###
  find: (query, fn) =>
    @current = null
    @list (err, usernames) =>
      if err
        return fn(err, usernames)
      if query.name in usernames
        console.log("GOT IT")
        # Get the user and application hash lookup
    fn(null, [])

  ###*
   * Searches for the redis object that matches the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) The callback function
  ###
  # find_one: (query, fn) =>
  #   @current = null
  #   @find query, (err, obj) ->
  #     fn(err, obj)

  ###*
   * Adds a new redis object of the current type to the database.
   * @param {Object} (obj) The object to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    return fn(null, false) unless @current
    target = @current

    user_prefix = [@prefix(), target.name].join('::')
    @all { name: true }, (err, usernames) =>
      if target.name in usernames
        @current = target
        return fn(null, false)

      target.secret = generate_identity()
      stat_add = @redis.sadd(''.concat(@prefix(), 's'), target.name)
      stat_hm = @redis.hmset(user_prefix, target)
      @current = target

      status = if (stat_add and stat_hm) then null else
        message: "Error saving user"
      return fn(status, @current)

  ###*
   * Deletes a redis object that matches the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) the callback function
  ###
  # delete: (fn) =>
  #   fn(null, true)

module.exports = User
