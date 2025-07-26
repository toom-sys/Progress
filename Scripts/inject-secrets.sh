#!/bin/bash

# inject-secrets.sh
# Injects environment variables into plist configuration files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS_DIR="$PROJECT_ROOT/Progress"

echo "🔧 Injecting secrets into configuration files..."

# Function to inject secrets into a plist file
inject_plist_secrets() {
    local plist_file="$1"
    local backup_file="${plist_file}.backup"
    
    if [ ! -f "$plist_file" ]; then
        echo "❌ Plist file not found: $plist_file"
        return 1
    fi
    
    echo "📝 Processing: $(basename "$plist_file")"
    
    # Create backup
    cp "$plist_file" "$backup_file"
    
    # Replace environment variable placeholders
    # Use a temporary file for safe replacement
    local temp_file="${plist_file}.tmp"
    
    # Process the file
    while IFS= read -r line; do
        # Replace ${VAR_NAME} patterns with environment variable values
        if [[ $line =~ \$\{([^}]+)\} ]]; then
            var_name="${BASH_REMATCH[1]}"
            var_value="${!var_name}"
            
            if [ -z "$var_value" ]; then
                echo "⚠️  Warning: Environment variable '$var_name' is not set"
                # Keep the placeholder if no value is found
                echo "$line"
            else
                # Replace the placeholder with the actual value
                echo "${line//\$\{$var_name\}/$var_value}"
            fi
        else
            echo "$line"
        fi
    done < "$plist_file" > "$temp_file"
    
    # Replace original with processed file
    mv "$temp_file" "$plist_file"
    
    echo "✅ Processed: $(basename "$plist_file")"
}

# Function to restore backup files
restore_backups() {
    echo "🔄 Restoring backup files..."
    
    for backup in "$PROGRESS_DIR"/*.plist.backup; do
        if [ -f "$backup" ]; then
            original="${backup%.backup}"
            mv "$backup" "$original"
            echo "📝 Restored: $(basename "$original")"
        fi
    done
}

# Function to clean up backup files
cleanup_backups() {
    echo "🧹 Cleaning up backup files..."
    
    for backup in "$PROGRESS_DIR"/*.plist.backup; do
        if [ -f "$backup" ]; then
            rm "$backup"
            echo "🗑️  Removed backup: $(basename "$backup")"
        fi
    done
}

# Handle command line arguments
case "${1:-inject}" in
    "inject")
        echo "🚀 Starting secret injection..."
        
        # RevenueCat configuration
        if [ -f "$PROGRESS_DIR/RevenueCat.plist" ]; then
            inject_plist_secrets "$PROGRESS_DIR/RevenueCat.plist"
        else
            echo "⚠️  RevenueCat.plist not found"
        fi
        
        # Firebase configuration
        if [ -f "$PROGRESS_DIR/GoogleService-Info.plist" ]; then
            inject_plist_secrets "$PROGRESS_DIR/GoogleService-Info.plist"
        else
            echo "⚠️  GoogleService-Info.plist not found"
        fi
        
        echo "✅ Secret injection completed"
        ;;
        
    "restore")
        restore_backups
        echo "✅ Backup restoration completed"
        ;;
        
    "cleanup")
        cleanup_backups
        echo "✅ Cleanup completed"
        ;;
        
    "help"|"-h"|"--help")
        echo "Usage: $0 [inject|restore|cleanup|help]"
        echo ""
        echo "Commands:"
        echo "  inject   - Inject environment variables into plist files (default)"
        echo "  restore  - Restore original plist files from backups"
        echo "  cleanup  - Remove backup files"
        echo "  help     - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "RevenueCat:"
        echo "  REVENUECAT_API_KEY"
        echo "  REVENUECAT_PUBLIC_SDK_KEY_IOS"
        echo "  REVENUECAT_ENVIRONMENT"
        echo ""
        echo "Firebase:"
        echo "  FIREBASE_CLIENT_ID"
        echo "  FIREBASE_REVERSED_CLIENT_ID"
        echo "  FIREBASE_API_KEY"
        echo "  FIREBASE_GCM_SENDER_ID"
        echo "  FIREBASE_PROJECT_ID"
        echo "  FIREBASE_STORAGE_BUCKET"
        echo "  FIREBASE_GOOGLE_APP_ID"
        echo "  FIREBASE_DATABASE_URL"
        ;;
        
    *)
        echo "❌ Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 