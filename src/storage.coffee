# Mix some handy methods into ChromeStorage object.

Q = require 'q'

fub = require './funcbag'
chmst = new (require './chrome_storage')(fub.INSTALL_TYPE == 'development')

# For having not only Refref models in the storage. Reserved for the
# future. For example, __options__
chmst.isValidHiddenKey = (name) ->
  name.match /^__[0-9A-Za-z_]+__$/

# See options.coffee for Refref model.
chmst.toArray = (raw_data) ->
  ((val.id = key; val) for key,val of raw_data when !@isValidHiddenKey(key))

# Fill google storage area with predefined options for several sites.
# Warning: clears every other data in the storage.
#
# Return a promise.
chmst.setDefaults = ->
  fub.puts 1, 'storage', 'cleaning & refilling'
  everybody_wants_this =
    '1':
      domain: 'wsj.com'
      referer: 'http://news.google.com'
    '2':
      domain: 'ft.com'
      referer: 'http://news.google.com'

  @clean()
  .then =>
    @set everybody_wants_this

# Load all models form the storage.
#
# Return a promise with an array of jsonified models.
chmst.load = ->
  fub.puts 1, 'storage', 'reading'
  @get()
  .then (result) =>
    @toArray result

module.exports = chmst
