# Exercise Images Setup

This document explains the exercise image assets that need to be added to complete the image support infrastructure.

## Image Sets Created

The following image sets have been created in Assets.xcassets:

1. **exercise_bench_press** - For "Bench Press" exercise
2. **exercise_squats** - For "Squats" exercise  
3. **exercise_deadlifts** - For "Deadlifts" exercise
4. **exercise_pull_ups** - For "Pull-Ups" exercise
5. **exercise_overhead_press** - For "Overhead Press" exercise
6. **exercise_bicep_curls** - For "Bicep Curls" exercise
7. **exercise_running** - For "Running" exercise

## Required Image Files

For each image set, you need to add the following PNG files:

- `exercise_[name].png` (1x resolution)
- `exercise_[name]@2x.png` (2x resolution) 
- `exercise_[name]@3x.png` (3x resolution)

## Image Specifications

- **Format**: PNG with transparency support
- **Style**: Simple, clean illustrations or icons
- **Colors**: Should work well with both light and dark modes
- **Size**: 
  - 1x: 60x60 points (60x60 pixels)
  - 2x: 120x120 pixels  
  - 3x: 180x180 pixels

## Fallback System

If image files are not present, the ExerciseImageService will automatically fall back to the SF Symbol `figure.strengthtraining.traditional` for a consistent user experience.

## Adding More Exercises

To add images for additional exercises:

1. Create a new `.imageset` folder in Assets.xcassets
2. Add the Contents.json file (copy from existing ones)
3. Update the `exerciseImageMap` in `ExerciseImageService.swift`
4. Add the actual PNG files to the imageset folder

## Testing

The service includes methods to test image availability:
- `hasSpecificImage(for:)` - Check if an exercise has a custom image
- `getAssetName(for:)` - Get the asset name for debugging
- `cacheInfo` - View cache statistics
