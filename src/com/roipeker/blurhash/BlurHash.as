// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 02/07/2020.
//
// =================================================================================================

/**
 * Non-official ActionScript 3 encoder/decoder for https://blurha.sh/
 *
 * Is not very optimized, so, as a rule of thumb encode/decode your bitmaps at 20-35px wide.
 *
 * If using Bitmaps directly, you have helper methods in ImageUtils.as,
 * setting the smoothing=true makes all the difference, visually.
 *
 * To take advantage of the Inlined methods, add "-inline" to your compiler options.
 *
 * My computer's benchmarks (running OSX with ADL/debugging desktop, and AIR 32) :
 * Using the sample code:
 * Encoding ~8ms : width=12px, grid=4x3 . output: LRGINI*0$,-M|REU#sT0:mae;0Em
 * Decoding ~4ms : width=30px (scaled to 300)
 *
 */
package com.roipeker.blurhash {
public class BlurHash {

    private static const _digitChars:Array = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "#", "$", "%", "*", "+", ",", "-", ".", ":", ";", "=", "?", "@", "[", "]", "^", "_", "{", "|", "}", "~"];

    public function BlurHash() {
        throw Error("BlurHash is an Utility class that can't be instantiated, use the available static methods instead.");
    }

    /**
     * Encodes "value" in base 83 format.
     * @param value     value to be encoded.
     * @param length    amount of chars.
     * @return String   ASCII code representation
     */
    [Inline]
    public static function encode83(value:Number, length:int):String {
        var result:String = "";
        var digit:Number;
        const val2:Number = Math.floor(value);
        for (var i:int = 1; i <= length; i++) {
            digit = (val2 / Math.pow(83, length - i)) % 83;
            result += _digitChars[int(digit)];
        }
        return result;
    }

    /**
     * Decodes a base 83 string into a Number.
     * @param str       String in base83.
     * @return Number
     */
    [Inline]
    public static function decode83(str:String):Number {
        var val:Number = 0;
        var len:int = str.length;
        for (var i:int = 0; i < len; i++) val = val * 83 + _digitChars.indexOf(str.charAt(i));
        return val;
    }


    /**
     * Encodes the pixel list to a hashed string.
     * @param pixels        List of 24bits pixels colors (usually taken from BitmapData::getVector())
     * @param width         Image width used to get the Vector.
     * @param height        Image height used to get the Vector.
     *                      defaults=0 calculates from pixels.length and width.
     * @param componentX    amount of horizontal information to be retained (max 9)
     * @param componentY    amount of vertical information to be retained (max 9)
     * @return  hashed String representation.
     */
    public static function encode(pixels:Vector.<uint>, width:int, height:int = 0, componentX:uint = 4, componentY:uint = 3):String {
        if (componentX < 1 || componentX > 9 || componentY < 1 || componentY > 9) throw new Error("BlurHash must have between 1 and 9 components");
        if (height == 0) height = pixels.length / width;
        if (width * height !== pixels.length) throw new Error("Width and height must match the pixels array");
        var factors:Array = [];
        var normalisation:int;
        const pi:Number = Math.PI;
        for (var y:int = 0; y < componentY; y++) {
            for (var x:int = 0; x < componentX; x++) {
                normalisation = x == 0 && y == 0 ? 1 : 2;
                var factor:Array = _multiplyBasisFunction(pixels, width, height, function (i:int, j:int):Number {
                    return normalisation *
                            Math.cos((pi * x * i) / width) *
                            Math.cos((pi * y * j) / height);
                });
                factors[factors.length] = factor;
            }
        }
        const dc:Array = factors[0];
        const ac:Array = factors.slice(1);
        var len:int, i:int;
        const sizeFlag:int = componentX - 1 + (componentY - 1) * 9;
        var maxValue:Number;
        var hash:String = encode83(sizeFlag, 1);
        if (ac.length > 0) {
            var actualMax:Number = 0;
            len = ac.length;
            for (i = 0; i < len; i++) for (var j:int = 0; j < 3; j++) if (ac[i][j] > actualMax) actualMax = ac[i][j];
            var quantisedMaximumValue:Number = Math.floor(Math.max(0, Math.min(82, Math.floor(actualMax * 166 - 0.5))));
            maxValue = (quantisedMaximumValue + 1) / 166;
            hash += encode83(quantisedMaximumValue, 1);
        } else {
            maxValue = 1;
            hash += encode83(0, 1);
        }
        hash += encode83(_encodeDC(dc), 4);
        for (i = 0, len = ac.length; i < len; i++) {
            hash += encode83(_encodeAC(ac[i], maxValue), 2);
        }
        return hash;
    }

    /**
     *  Decodes the blurshash into a pixel list.
     *
     * @param blurhash  The hashed String that represents the image.
     * @param width     image width
     * @param height    image height
     * @param punch     constrast, bigger number creates more dramatic effect.
     *                  Technically, what it does is scale the AC components up or down.
     * @return          Vector<uint>, 24bit pixel colors to be applied in BitmapData.
     */
    public static function decode(blurhash:String, width:uint, height:uint, punch:Number = 1):Vector.<uint> {
        validate(blurhash);
        if (isNaN(punch)) punch = 1;
        const sizeFlag:Number = decode83(blurhash.charAt(0));
        const ny:Number = Math.floor(sizeFlag / 9) + 1;
        const nx:Number = (sizeFlag % 9) + 1;
        var quantisedMaximumValue:Number = decode83(blurhash.charAt(1));
        var maximumValue:Number = (quantisedMaximumValue + 1) / 166;
        var colors:Array = [];// use vector. array of array!

        var len:int = nx * ny;
        var val83:Number;
        var i:int, x:int, y:int;
        for (i = 0; i < len; i++) {
            if (i == 0) {
                val83 = decode83(blurhash.substring(2, 6));
                colors[i] = _decodeDC(val83);
            } else {
                val83 = decode83(blurhash.substring(4 + i * 2, 6 + i * 2));
                colors[i] = _decodeAC(val83, maximumValue * punch);
            }
        }

        const pixels:Vector.<uint> = new Vector.<uint>(); // weird one
        var r:Number = 0, g:Number = 0, b:Number = 0;
        var basis:Number;
        var color:Vector.<Number>;

        len = width * height;
        var col:int, row:int;
        const pi:Number = Math.PI;

        for (i = 0; i < len; i++) {
            x = i % width | 0;
            y = i / width | 0;
            r = g = b = 0;
            for (row = 0; row < ny; row++) {
                for (col = 0; col < nx; col++) {
                    basis = Math.cos((pi * x * col) / width) * Math.cos((pi * y * row) / height);
                    color = colors[int(col + row * nx)];
                    r += color[0] * basis;
                    g += color[1] * basis;
                    b += color[2] * basis;
                }
            }
            var intR:uint = _linearTosRGB(r);
            var intG:uint = _linearTosRGB(g);
            var intB:uint = _linearTosRGB(b);
            pixels[pixels.length] = 255 << 24 | intR << 16 | intG << 8 | intB;
        }
        return pixels;
    }

    /**
     * This validation only throws an exception with the error.
     * @param blurhash  The hashed String.
     */
    public static function validate(blurhash:String):void {
        if (!blurhash || blurhash.length < 6) {
            throw new Error("The blurhash string must be at least 6 characters");
        }
        const sizeFlag:Number = BlurHash.decode83(blurhash.charAt(0));
        const ny:Number = Math.floor(sizeFlag / 9) + 1;
        const nx:Number = (sizeFlag % 9) + 1;
        const expected:Number = 4 + 2 * nx * ny;
        if (blurhash.length != expected) {
            throw new Error("blurhash length mismatch: length is " + blurhash.length + ", but should be " + expected);
        }
    }

    /**
     * Validates the hashed string without throwing errors.
     * @param blurhash  The hashed String.
     * @return  Boolean true if it's valid.
     */
    public static function isValid(blurhash:String):Boolean {
        try {
            BlurHash.validate(blurhash);
        } catch (e:Error) {
            trace(e);
            return false;
        }
        return true;
    }


    [Inline]
    private static function _sRGBToLinear(value:Number):Number {
        var v:Number = value / 255.0;
        if (v <= 0.04045) {
            return v / 12.92;
        } else {
            return Math.pow((v + 0.055) / 1.055, 2.4);
        }
    }

    [Inline]
    private static function _linearTosRGB(value:Number):Number { // base 255
        var v:Number = Math.max(0, Math.min(1, value));
        if (v <= 0.0031308) {
            return (v * 12.92 * 255 + 0.5);
        } else {
            return (((1.055 * Math.pow(v, 1 / 2.4) - 0.055) * 255 + 0.5));
        }
    }

    [Inline]
    private static function _decodeDC(value:uint):Vector.<Number> {
        return Vector.<Number>([BlurHash._sRGBToLinear(value >> 16), _sRGBToLinear((value >> 8) & 255), _sRGBToLinear(value & 255)]);
    }

    [Inline]
    private static function _decodeAC(value:Number, maxValue:Number):Vector.<Number> {
        return Vector.<Number>([
            _signPow((Math.floor(value / (19 * 19)) - 9) / 9, 2.0) * maxValue,
            _signPow((Math.floor(value / 19) % 19 - 9) / 9, 2.0) * maxValue,
            _signPow((value % 19 - 9) / 9, 2.0) * maxValue
        ]);
    }

    [Inline]
    private static function _encodeDC(value:Array):uint {
        return (_linearTosRGB(value[0]) << 16)
                + (_linearTosRGB(value[1]) << 8)
                + _linearTosRGB(value[2]);
    }

    [Inline]
    private static function _encodeAC(value:Array, maxValue:Number):Number {
        return _bounds(value[0], maxValue) * 19 * 19 +
                _bounds(value[1], maxValue) * 19 +
                _bounds(value[2], maxValue);
    }

    static private function _multiplyBasisFunction(pixels:Vector.<uint>, width:int, height:int, basisFunction:Function):Array {
        var r:Number = 0, g:Number = 0, b:Number = 0;
        var basis:Number;
        var color:uint;
        for (var x:int = 0; x < width; x++) {
            for (var y:int = 0; y < height; y++) {
                basis = basisFunction(x, y);
                color = pixels[int(x + y * width)];
                r += basis * _sRGBToLinear(color >> 16 & 0xFF);
                g += basis * _sRGBToLinear(color >> 8 & 0xFF);
                b += basis * _sRGBToLinear(color & 0xFF);
            }
        }
        const scale:Number = 1 / (width * height);
        return [r * scale, g * scale, b * scale];
    }

    [Inline]
    private static function _sign(n:Number):int {
        return n < 0 ? -1 : 1;
    }

    [Inline]
    private static function _signPow(val:Number, exp:Number):Number {
        return _sign(val) * Math.pow(Math.abs(val), exp);
    }

    [Inline]
    static private function _bounds(val:Number, maxValue:Number):Number {
        return Math.floor(Math.max(0, Math.min(18, _signPow(val / maxValue, .5) * 9 + 9.5)));
    }
}
}
