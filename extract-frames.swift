#!/usr/bin/swift
/*
 This is taken from a lab at RWDevcon 2017 and I didn't write it.  Just upgraded it and stuff.
 
 This is a macOS Swift 4 command line tool which reads a QuickTime movie file
 and writes a set of JPEG images of all the frames in the movie.
 
 Run it directly, or compile it and run the executable. If you run it without
 command-line arguments, it will describe its required arguments

 Known-good: Xcode 9.2, macOS 10.13.2

 */

import Foundation
import AVFoundation

// MARK: file i/o

/// reads a movie file and writes its frames as images
func lazilyExtractFrames(fromRelativeMoviePath path:String,
                         frameIndexes:[String]?,
                         toPath destPath:String) -> Bool
{
  let destURL = URL(fileURLWithPath:destPath)
  let movieURL = URL(fileURLWithPath:path)
  let numberIndexes:[Int]? = frameIndexes?.flatMap({Int($0)})
  
  var indexes:Set<Int>?
  if let x = numberIndexes {
    indexes = Set(x)
  }
  else {
    indexes = nil
  }

  var framesProcseedCount:Int = 0
  var imagesWrittenSuccessfullyCount:Int = 0
  var imagesWrittenUnsuccessfullyCount:Int = 0
  
  var success:Bool = true
  
  for (frameIndex,c) in MovieFrameSequence(movie: movieURL).enumerated() {
    framesProcseedCount += 1
    let outfileURL = destURL.appendingPathComponent("frame-\(frameIndex).jpg")
    if indexes == nil // no indexes means get them all
      || (indexes!.remove(frameIndex) != nil)
    {
      let writeSuccess = writeCGImage(c, toPath: outfileURL)
      if !writeSuccess {
        NSLog("Error writing file to \(outfileURL)")
        success = false
        imagesWrittenUnsuccessfullyCount += 1
      }
      else {
        imagesWrittenSuccessfullyCount += 1
      }
    }
  }
  print("frames processed = \(framesProcseedCount)")
  print("images written = \(imagesWrittenSuccessfullyCount)")
  print("images written unsuccesfully = \(imagesWrittenUnsuccessfullyCount)")
  return success
}

/// Writes an image as a JPEG to a path
fileprivate func writeCGImage(_ image: CGImage, toPath path: URL) -> Bool
{
  guard 
    let destination = CGImageDestinationCreateWithURL(path as CFURL, kUTTypeJPEG, 1, nil)  else { return false }
  CGImageDestinationAddImage(destination, image, nil)
  return CGImageDestinationFinalize(destination)
}

// MARK: - MovieFrameSequence

/// Sequence of images extracted from a movie URL
class MovieFrameSequence : Sequence {
  let videoAsset:AVURLAsset
  
  init(movie:URL) {
    videoAsset = AVURLAsset(url: movie as URL)
  }
  
  func makeIterator() -> MovieFrameIterator {
    return MovieFrameIterator(self.videoAsset)
  }
}

class MovieFrameIterator : IteratorProtocol
{
  // Create a device-dependent RGB color space.
  let colorSpace = CGColorSpaceCreateDeviceRGB();
  
  let readerOutput:(AVAssetReader,AVAssetReaderTrackOutput)?
  
  init(_ videoAsset:AVURLAsset)
  {
    do {
      guard
        let videoAssetReader = try? AVAssetReader(asset: videoAsset),
        let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first
        else { print("fart");throw NSError() }
      let outputSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
      let videoTrackOutput = AVAssetReaderTrackOutput(track:videoTrack,
                                                      outputSettings:outputSettings)
      videoTrackOutput.alwaysCopiesSampleData = false
      guard videoAssetReader.canAdd(videoTrackOutput) else { throw NSError() }
      videoAssetReader.add(videoTrackOutput)
      guard videoAssetReader.startReading() else { throw NSError() }
      readerOutput = (videoAssetReader,videoTrackOutput)
    }
    catch {
      readerOutput = nil
    }
  }
  
  func next() -> CGImage?
  {
    // if we cannot read frames, we're finished
    guard
      let (videoAssetReader,videoTrackOutput) = readerOutput,
      videoAssetReader.status == .reading,
      let sampleBuffer = videoTrackOutput.copyNextSampleBuffer(),
      let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
      else { return nil }
    
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,CVPixelBufferLockFlags.readOnly);
    
    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    let width = CVPixelBufferGetWidth(imageBuffer);
    let height = CVPixelBufferGetHeight(imageBuffer);
    
    // Get the base address of the pixel buffer.
    let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    
    // Create a bitmap image from data supplied by the data provider.
    let context = CGContext(data: baseAddress,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: bytesPerRow,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    
    guard let cgimage = context.makeImage() else {
      fatalError("failure creating image from bitmap context")
    }
    // Create and return an image object to represent the Quartz image.
    
    CVPixelBufferUnlockBaseAddress(imageBuffer,
                                   CVPixelBufferLockFlags.readOnly);
    return cgimage
  }
}


// MARK: - command-line wrapper

// get command-line args
guard 
  let inputMoviePath = UserDefaults.standard.string(forKey:"inputMoviePath"),
  let outputImagesPath = UserDefaults.standard.string(forKey:"outputImagesPath")
else {
    print("usage: extract-frames -inputMoviePath PATH_TO_INPUT_MOVIE -outputImagesPath PATH_TO_OUTPUT_DIRECTORY")
    print("")
    print("  Did not find required command-line arguments")
    exit(1)
}


let success = lazilyExtractFrames(fromRelativeMoviePath: inputMoviePath,
                                  frameIndexes:nil,
                                  toPath:outputImagesPath)

let exitCode:Int32 = (success == true) ? 0 : 1
exit(exitCode)

