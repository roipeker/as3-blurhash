package {

import com.roipeker.blurhash.ImageUtils;

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.utils.getTimer;
import flash.utils.setTimeout;

[SWF(width="800", height="600", backgroundColor="#FFFFFF", frameRate="60")]

public class Main extends Sprite {
    public function Main() {
        setTimeout(init, 60);
    }

    private function init():void {
        testDecode();
//        testEncode();
//        testHashTransition();
    }

    private function testDecode():void {
//        var hashString:String = 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.';
//        var hashString:String = ':6Pj0^i_.AyE8^m+%gt,_3t7t7R*WBs,ofR-*0o#DgR4.Tt,ITVY_3R*D%xt%MIpRj%0McV@%itSI9R5x]tRIot7-:IoM{%LoeIVNHoft7M{RkxuozM{%1WBg4tRV@M{kCxu';
//        var hashString:String = 'LEHV6nWB2yk8pyoJadR*.7kCMdnj';
//        var hashString:String = 'qEHV6nWB2yk8$NxujFNGpyoJadR*=ss:I[R%.7kCMdnjx]S2NHs:S#M|%1%2ENRis9a$Sis.slNHW:WBxZ%2ogaekBW;ofo0NHS4';
//        var hashString:String = 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.';
//        var hashString:String = 'L6Pj0^i_.AyE_3t7t7R**0o#DgR4';
        var hashString:String = 'LEHV6nWB2yk8pyoJadR*.7kCMdnj';

        // reference image = 162x90
        var aspect:Number = 90 / 162;

        var blurImage:Bitmap = ImageUtils.getBitmapFromHash(hashString, 200, 200 * aspect, 1, 20);
        addChild(blurImage);
    }


    private function testEncode():void {
//        var url:String = 'https://placekitten.com/200/100';
//        var url:String = 'https://blurha.sh/assets/images/img1.jpg';
//        var url:String = 'https://blurha.sh/assets/images/img2.jpg';
//        var url:String = 'https://placekitten.com/300/200';
//        var url:String = 'https://placekitten.com/800/600';
//        var url:String = 'https://placekitten.com/1200/1200';
//        var url:String = 'https://placekitten.com/2000/1400';
//        var url:String = 'https://placekitten.com/3000/3000';
//        var url:String = 'https://placekitten.com/2200/2200';
        var url:String = 'https://images.unsplash.com/photo-1492095664363-4ca82097ec8a?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1954&q=80';
//        var url:String = 'https://images.unsplash.com/photo-1491489030622-1afc3b19b8c8?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=958&q=80';

        var container:Sprite = new Sprite();
        addChild(container);

        ImageUtils.loadBitmap(url, onImageLoaded);

        function onImageLoaded(bitmap:Bitmap):void {
            container.addChild(bitmap);
            container.width = 300;
            container.scaleY = container.scaleX;

            var ratio:Number = bitmap.width / bitmap.height;

            // track time.
            var t:int;
            t = getTimer();
            var hashed:String = ImageUtils.getHashFromBitmapData(bitmap.bitmapData, 4, 3, 20);
            trace('Time spent encoding bitmap to hash:', getTimer() - t);
            trace('blurhash:', hashed);

            t = getTimer();
            var bitmapW:int = container.width;
            var bitmapH:int = container.width / ratio;
            var decodedBitmap:Bitmap = ImageUtils.getBitmapFromHash(hashed, bitmapW, bitmapH, 1, 32);
            trace('Time spent decoding hash to bitmap:', getTimer() - t);
            addChild(decodedBitmap);

            decodedBitmap.height = container.height;

//            decodedBitmap.smoothing = false;
            decodedBitmap.x = container.x + container.width + 10;
        }
    }

    private function testHashTransition():void {
//        var hashed:String = 'LFJhwKxG_PD%=JFvw|wJ+I1HFw?H';
//        var url:String = 'https://placekitten.com/2000/2000';

//        var hashed:String = 'qFF~N*^i4:ozx]adjEt7T#9F%2RkoJxaoJt7^*ITo#V@IUt7bIRjT1WBs,xuaeM{WBWByEkXMxxat7WBWVj]%1xaIUs.xubbofof';
//        var url:String = 'https://placekitten.com/2200/2200';
//        var url:String = 'https://images.unsplash.com/photo-1492095664363-4ca82097ec8a?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1954&q=80';
//        var hashed:String = 'LQCZU@?aocWC?wxvj[j[pJW=WCof';

        var url:String = 'https://images.unsplash.com/photo-1491489030622-1afc3b19b8c8?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=958&q=80';
        var hashed:String = 'LtH_xxE4oes:.TR,R+kCElxFaya~';
        var ratio:Number = 454 / 635; // for the last image...

        var tw:int = 300;
        var th:int = tw / ratio;

        var img:Sprite = new Sprite();
        addChild(img);
        img.x = stage.stageWidth - tw >> 1;
        img.y = stage.stageHeight - th >> 1;

        var blurImage:Bitmap = ImageUtils.getBitmapFromHash(hashed, tw, th, 1, 32);
        img.addChild(blurImage);
        blurImage.height = th;

        var remoteImage:Bitmap = new Bitmap();
        ImageUtils.loadBitmap(url, function (bitmap:Bitmap) {
            remoteImage.bitmapData = bitmap.bitmapData;
            remoteImage.width = tw;
            remoteImage.height = th;
            img.addChildAt(remoteImage, 0);

            setTimeout(fadeOutBlur, 1200);
        });

        function fadeOutBlur():void {
            addEventListener(Event.ENTER_FRAME, function (e:Event) {
                blurImage.alpha += (0 - blurImage.alpha) * .012;
                if (blurImage.alpha < .001) {
                    removeEventListener(e.type, arguments.callee);
                    if (blurImage.parent) blurImage.parent.removeChild(blurImage);
                }
            });
        }
    }

}
}
