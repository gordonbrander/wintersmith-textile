textile = require 'textile-js'
{ Highlight } = require 'highlight'

async = require 'async'
path = require 'path'
fs = require 'fs'

Page = require 'wintersmith/lib/plugins/page'

parseTextile = (content) ->
   json = textile.jsonml(content)

   tokens = []

   for elem in json.slice(1)
      switch elem[0]
         when 'pre'
            html = Highlight textile.serialize(elem), '  ', true
            tokens.push(html)
         else
            tokens.push(textile.serialize(elem));

   return tokens.join('\n')


parseMetadata = (metadata, callback) ->
  ### takes *metadata* in the format:
        key: value
        foo: bar
      returns parsed object ###

  rv = {}
  try
    lines = metadata.split '\n'

    for line in lines
      pos = line.indexOf ':'
      key = line.slice(0, pos).toLowerCase()
      value = line.slice(pos + 1).trim()
      rv[key] = value

    callback null, rv

  catch error
    callback error

extractMetadata = (content, callback) ->
   
   split_idx = content.indexOf '\n\n'

   async.parallel
      metadata: (callback) ->
         parseMetadata content.slice(0, split_idx), callback
      markdown: (callback) ->
         callback null, content.slice(split_idx + 2)
      , callback

module.exports = (wintersmith, callback) ->

   class TextilePage extends Page

      getLocation: (base) ->
         uri = @getUrl base
         return uri[0..uri.lastIndexOf('/')]

      getHtml: (base) ->
         @_html = parseTextile(@_content)
         return @_html

   TextilePage.fromFile = (filename, base, callback) ->
      async.waterfall [
         (callback) ->
            fs.readFile path.join(base, filename), callback
         (buffer, callback) ->
            extractMetadata buffer.toString(), callback
         (result, callback) =>
            {markdown, metadata} = result
            page = new this filename, markdown, metadata
            callback null, page
      ], callback


   wintersmith.registerContentPlugin 'pages', '**/*.*(textile)', TextilePage

   callback()
