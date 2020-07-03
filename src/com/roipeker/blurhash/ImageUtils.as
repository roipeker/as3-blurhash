// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 03/07/2020.
//
// =================================================================================================

/**
 * Helper class for BlurHash.
 * Contains some utility functions to generate bitmaps,
 * and computed hashed Strings.
 */
package com.roipeker.blurhash {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.Sprite;
import flash.display.StageQuality;
import flash.events.Event;
import flash.net.URLRequest;

public class ImageUtils {

    private static var _drawingSprite:Sprite;

    public function ImageUtils() {
    };

    /**
     * Helper method. Decodes a blurhash string into a bitmapData and outputs the
     * (optionally) scaled Bitmap.
     *
     * @param blurhash          The hashed string.
     * @param scaledWidth       Final output width of the bitmap (scaled)
     * @param scaledHeight      Final output height of the bitmap (scaled)
     * @param punch             @see BlurHash.decode()::punch
     * @param actualImageWidth  real bitmapData width to be computed (smaller = faster),
     *                          defaults 25px
     * @param bufferedBitmap    Optional Bitmap instance to apply the bitmapData and to scale.
     * @return                  Bitmap with scaled size.
     */
    public static function getBitmapFromHash(blurhash:String, scaledWidth:int, scaledHeight:int, punch:Number = 1, actualImageWidth:int = 25, bufferedBitmap:Bitmap = null):Bitmap {
        if (scaledWidth <= 0 || scaledHeight <= 0) {
            throw new Error('ImageUtils::getBitmapFromHash(), scaledHeight or scaledWidth can\'t be 0, negative or null');
        }
        if (actualImageWidth <= 0) actualImageWidth = scaledWidth;
        if (actualImageWidth <= 3) actualImageWidth = 25;

        var imageAspectRatio:Number = scaledWidth / scaledHeight;
        var tw:int = actualImageWidth;
        var th:int = tw / imageAspectRatio;
        var scale:Number = scaledWidth / tw;

        var pixels:Vector.<uint> = BlurHash.decode(blurhash, tw, th, punch);

        var bd:BitmapData = new BitmapData(tw, th, false, 0x0);
        bd.setVector(bd.rect, pixels);

        if (!bufferedBitmap) bufferedBitmap = new Bitmap();
        bufferedBitmap.bitmapData = bd;
        bufferedBitmap.smoothing = true;
        bufferedBitmap.scaleX = bufferedBitmap.scaleY = scale;
        return bufferedBitmap;
    }

    /**
     * Helper method to encode a bitmapData into a blurHash String.
     *
     * @param bitmapData            the bitmapData to be encoded
     * @param componentX            @see BlurHash.encode()::componentX
     *                              defaults=4
     * @param componentY            @see BlurHash.encode()::componentY
     *                              defaults=3
     * @param computedImageWidth    output width to be computed (smaller = faster),
     *                              defaults 30px, if BitmapData is bigger than 60px,
     *                              it will create a thumbnail version of this size.
     *                              If computedImageWidth=0, it will use the original bitmapData
     *                              and it will be overkill.
     * @return                      hashed string
     */
    public static function getHashFromBitmapData(bitmapData:BitmapData, componentX:int = 4,
                                                 componentY:int = 3, computedImageWidth:int = 30):String {
        if (computedImageWidth <= 0) computedImageWidth = bitmapData.width;

        var smallEnough:Boolean = bitmapData.width < 60 && bitmapData.height < 60;

        if (computedImageWidth >= 60 && (bitmapData.width > 60 || bitmapData.height > 60)) {
            trace("WARNING: getHashFromBitmapData(), encoding the blurhash might take a while for big images (CPU hit).\n" +
                    "Use ::computedImageWidth parameter to generate a thumb version of the bitmapData,\nor provide a smaller" +
                    "one (ex 20-35px wide)");
        }

        if (componentX > 9 || componentX < 1) {
            trace("WARNING: getHashFromBitmapData(), overflow value for componentX (will reduce performance).\nCasting values to recommended settings: 4");
            componentX = 4;
        }
        if (componentY > 9 || componentX < 1) {
            trace("WARNING: getHashFromBitmapData(), overflow value for componentY (will reduce performance).\nCasting values to recommended settings: 3");
            componentY = 3;
        }

        var bd:BitmapData;
        var bmp:Bitmap;
        if (!smallEnough) {
            // create a new thumbnail version.
            var imageRatio:Number = bitmapData.width / bitmapData.height;
            var tw:int = computedImageWidth;
            var th:int = computedImageWidth / imageRatio;
            var scaleRatio:Number = bitmapData.width / tw;

            if (!_drawingSprite) {
                _drawingSprite = new Sprite();
                _drawingSprite.addChild(new Bitmap());
            }

            bmp = _drawingSprite.getChildAt(0) as Bitmap;
            bmp.bitmapData = bitmapData;
            bmp.scaleX = bmp.scaleY = 1 / scaleRatio;

            bd = new BitmapData(tw, th, false, 0x0);
            bd.drawWithQuality(_drawingSprite, null, null, null, null, false, StageQuality.BEST);

            bitmapData = bd;
        }

        var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
        var output:String = BlurHash.encode(pixels, bitmapData.width, bitmapData.height, componentX, componentY);
        if (bd != null) bd.dispose();
        if (bmp != null) bmp.bitmapData = null;
        bmp = null;
        bd = null;
        return output;
    }

    /**
     * Simple loader callback (without error nor progress handler).
     * @param url                   image url to load
     * @param onComplete(?Bitmap)   callback with the (optional) bitmap
     * @param tempLoader            reusable Loader instance?
     * @return                      Created Loader or tempLoader.
     */
    public static function loadBitmap(url:String, onComplete:Function, tempLoader:Loader = null):Loader {
        if (!tempLoader) tempLoader = new Loader();
        tempLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, _onImageLoaded);
        tempLoader.load(new URLRequest(url));

        function _onImageLoaded(e:Event):void {
            tempLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, _onImageLoaded);
            var bitmap:Bitmap = tempLoader.contentLoaderInfo.content as Bitmap;
            bitmap.smoothing = true;
            if (onComplete != null) {
                if (onComplete.length == 1) onComplete(bitmap);
                else onComplete();
            }
        }

        return tempLoader;
    }
}
}
