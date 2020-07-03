# BlurHash for ActionScript 3.0.
is a [BlurHash](https://blurha.sh) encoder/decoder implementation in ActionScript 3.0.

Based on https://blurha.sh/

Check Main.as for usage samples.

## How to use it

Example usage of decoder:

Usage in pure AS3
```actionscript
//Image hash to be decoded
var hashed:String = 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH';
//Image placeholder
var img:Sprite = new Sprite();
addChild(img);
//Load image from hash
var blurImage:Bitmap = ImageUtils.getBitmapFromHash(hashed, tw, th, 1, 32);
img.addChild(blurImage);
```

Usage in Apache Flex
```actionscript
//Image hash to be decoded
var hashString:String = 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH';
//Container can be any UI Element used as placehodler (ex. Group)
var decodedBitmap:Bitmap = ImageUtils.getBitmapFromHash(hashString, container.width, container.height, 1, 32);
myImgComponent.source = decodedBitmap.bitmapData;
//Enable smooth in Image or BitmapImage for best result
myImgComponent.smooth=true;
```

## Contributing

Issues, feature requests or improvements welcome!

## Licence

This project is licensed under the [GPL-3.0 License](LICENSE).
