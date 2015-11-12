(function() {
  var RIFFBuilder, _, assert;

  assert = require('assert');

  _ = require('underscore');

  module.exports = function(formType) {
    return new RIFFBuilder(formType);
  };

  RIFFBuilder = (function() {
    function RIFFBuilder(formType) {
      this.buf = new Buffer(0);
      this._pushId('RIFF');
      this._pushUInt32(4);
      this._pushId(formType);
    }

    RIFFBuilder.prototype.pushChunk = function(chunkId, data) {
      this._pushId(chunkId);
      this._pushUInt32(data.length);
      if (data.length) {
        this._push(data);
      }
      if (data.length & 0x01) {
        this._padding();
      }
      return this;
    };

    RIFFBuilder.prototype.buffer = function() {
      this.buf.writeUInt32LE(this.tell() - 8, 4);
      return this.buf;
    };

    RIFFBuilder.prototype.tell = function() {
      return this.buf.length;
    };

    RIFFBuilder.prototype._push = function(buf, start, end) {
      var b;
      b = buf;
      if (_.isNumber(start)) {
        if (_.isNumber(end)) {
          b = buf.slice(start, end);
        } else {
          b = buf.slice(start);
        }
      }
      this.buf = Buffer.concat([this.buf, b]);
      return this;
    };

    RIFFBuilder.prototype._pushUInt32 = function(value) {
      var b;
      b = new Buffer(4);
      b.writeUInt32LE(value, 0);
      this._push(b);
      return this;
    };

    RIFFBuilder.prototype._pushId = function(value) {
      var b;
      assert.ok(_.isString(value), "Id msut be string. id:" + value);
      b = new Buffer(value, 'ascii');
      assert.ok(b.length === 4, "Id msut be 4 characters string. id:" + value);
      this._push(b);
      return this;
    };

    RIFFBuilder.prototype._padding = function(value) {
      this._push(new Buffer([0]));
      return this;
    };

    return RIFFBuilder;

  })();

}).call(this);
