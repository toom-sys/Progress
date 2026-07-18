#!/bin/bash

# Script to verify background task configuration
# This script checks if the background task identifiers are properly configured

echo "🔍 Verifying Background Task Configuration..."
echo "=============================================="

# Check if we can find the project file
if [ ! -f "Progress.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Progress.xcodeproj not found in current directory"
    echo "   Please run this script from the project root directory"
    exit 1
fi

echo "✅ Found Xcode project file"

# Check for background modes in project file
echo ""
echo "🔍 Checking for Background Modes configuration..."

if grep -q "UIBackgroundModes" Progress.xcodeproj/project.pbxproj; then
    echo "✅ UIBackgroundModes found in project configuration"
    
    if grep -q "background-app-refresh" Progress.xcodeproj/project.pbxproj; then
        echo "✅ background-app-refresh mode configured"
    else
        echo "⚠️  background-app-refresh mode NOT found"
    fi
    
    if grep -q "background-processing" Progress.xcodeproj/project.pbxproj; then
        echo "✅ background-processing mode configured"
    else
        echo "⚠️  background-processing mode NOT found"
    fi
else
    echo "❌ UIBackgroundModes NOT found in project configuration"
    echo "   You need to add Background Modes capability in Xcode"
fi

# Check for background task identifiers
echo ""
echo "🔍 Checking for Background Task Identifiers..."

if grep -q "BGTaskSchedulerPermittedIdentifiers" Progress.xcodeproj/project.pbxproj; then
    echo "✅ BGTaskSchedulerPermittedIdentifiers found in project configuration"
    
    if grep -q "com.tom.progress.cache-refresh" Progress.xcodeproj/project.pbxproj; then
        echo "✅ cache-refresh task identifier configured"
    else
        echo "⚠️  cache-refresh task identifier NOT found"
    fi
    
    if grep -q "com.tom.progress.cache-maintenance" Progress.xcodeproj/project.pbxproj; then
        echo "✅ cache-maintenance task identifier configured"
    else
        echo "⚠️  cache-maintenance task identifier NOT found"
    fi
else
    echo "❌ BGTaskSchedulerPermittedIdentifiers NOT found in project configuration"
    echo "   You need to add the task identifiers in Xcode Info tab"
fi

echo ""
echo "📋 Summary:"
echo "==========="

# Count configured items
bg_modes_count=0
task_ids_count=0

if grep -q "background-app-refresh" Progress.xcodeproj/project.pbxproj; then
    ((bg_modes_count++))
fi

if grep -q "background-processing" Progress.xcodeproj/project.pbxproj; then
    ((bg_modes_count++))
fi

if grep -q "com.tom.progress.cache-refresh" Progress.xcodeproj/project.pbxproj; then
    ((task_ids_count++))
fi

if grep -q "com.tom.progress.cache-maintenance" Progress.xcodeproj/project.pbxproj; then
    ((task_ids_count++))
fi

echo "Background Modes: $bg_modes_count/2 configured"
echo "Task Identifiers: $task_ids_count/2 configured"

if [ $bg_modes_count -eq 2 ] && [ $task_ids_count -eq 2 ]; then
    echo ""
    echo "🎉 All background task configuration is complete!"
    echo "   You can now test the background functionality"
else
    echo ""
    echo "⚠️  Configuration incomplete. Please follow the instructions in:"
    echo "   Progress/Scripts/add-background-tasks-to-xcode.md"
fi

echo ""
echo "🧪 To test after configuration:"
echo "   1. Build and run the app"
echo "   2. Check console for: '✅ Background tasks registered successfully'"
echo "   3. Go to Settings → Debug → Background Tasks"
