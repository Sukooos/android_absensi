import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  // Create a new image with a white background
  final image = img.Image(width: 512, height: 512);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  
  // Draw a simple circle in the center
  img.fillCircle(image, 
    x: 256,  // center x
    y: 256,  // center y
    radius: 128,
    color: img.ColorRgb8(33, 150, 243)  // Material Blue
  );
  
  // Save the image
  final png = img.encodePng(image);
  File('assets/image.png').writeAsBytesSync(png);
  
  print('Icon generated successfully!');
} 