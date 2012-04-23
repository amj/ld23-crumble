window.sm = sm = {}

class SoundMap
  sound_map: {}
  constructor: (context, sound_map, callback) ->
    @context = context
    @sound_map = sound_map
    @onload = callback
    @bufferList = {}
    @loadCount = 0 
    @loadBuffer(key, url) for key, url of @sound_map

  loadBuffer: (key, url) ->
    # Load buffer asynchronously
    console.log "Key, url: #{key}, #{url}"
    request = new XMLHttpRequest()
    request.open("GET", url, true)
    request.responseType = "arraybuffer"
    loader = this

    request.onload = () ->
      #// Asynchronously decode the audio file data in request.response
      loader.context.decodeAudioData(
        request.response,
        (buffer) ->
          if (!buffer)
            alert('error loading sound file: ' + url)
            return

          loader.sound_map[key] = buffer
          if (++loader.loadCount == Object.keys(loader.sound_map).length)
            loader.onload(loader)

          console.log "decoded #{key}, #{loader.loadCount} of #{Object.keys(loader.sound_map).length} remaining"
        )

    request.onerror = ->
      alert('BufferLoader: XHR error')

    request.send()

  playSound: (key, volume) ->
    if !volume
      volume = .7
    node = @context.createGainNode()
    node.gain.value = volume
    console.log "playSound: #{key}: #{@sound_map[key]}"
    source = @context.createBufferSource()
    source.buffer = @sound_map[key]
    source.connect(node)
    node.connect(@context.destination)
    source.noteOn(0)


###
function BufferLoader(context, urlList, callback) {
  this.context = context;
  this.urlList = urlList;
  this.onload = callback;
  this.bufferList = new Array();
  this.loadCount = 0;
}

BufferLoader.prototype.loadBuffer = function(url, index) {
  // Load buffer asynchronously
  var request = new XMLHttpRequest();
  request.open("GET", url, true);
  request.responseType = "arraybuffer";

  var loader = this;

  request.onload = function() {
    // Asynchronously decode the audio file data in request.response
    loader.context.decodeAudioData(
      request.response,
      function(buffer) {
        if (!buffer) {
          alert('error decoding file data: ' + url);
          return;
        }
        loader.bufferList[index] = buffer;
        if (++loader.loadCount == loader.urlList.length)
          loader.onload(loader.bufferList);
      }
    );
  }

  request.onerror = function() {
    alert('BufferLoader: XHR error');
  }

  request.send();
}

BufferLoader.prototype.load = function() {
  for (var i = 0; i < this.urlList.length; ++i)
  this.loadBuffer(this.urlList[i], i);
}
###

sm.SoundMap = SoundMap
snd_ctx = new webkitAudioContext
_map = {
  fall: 'sound/fall.mp3'
  nooo: 'sound/nooo.mp3'
  hehe: 'sound/hehe.mp3'
}
window.sounds = new SoundMap( snd_ctx, _map, (_sound_map) ->
        console.log 'loader callback!'
    )
