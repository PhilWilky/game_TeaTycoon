[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$ProjectRoot = Get-Location
$OutputFile = "$ProjectRoot\project-structure.md"
$GitIgnorePath = Join-Path $ProjectRoot ".gitignore"

# Additional manual ignores (optional - can be customized per project)
$ManualIgnores = @(
    # Add any extra patterns here, e.g.:
    # "*.log"
    # "temp/"
    ".git/"
    "*.tmp"
)

$global:MarkdownLines = @()
$global:FileCount = 0
$global:FolderCount = 0
$global:IgnorePatterns = @()

function Parse-GitIgnore {
    param([string]$gitignorePath)
    
    if (-not (Test-Path $gitignorePath)) {
        Write-Host "⚠️  No .gitignore found - showing all files" -ForegroundColor Yellow
        return @()
    }
    
    Write-Host "✅ Found .gitignore - parsing patterns..." -ForegroundColor Green
    
    $patterns = @()
    $lines = Get-Content $gitignorePath -ErrorAction SilentlyContinue
    
    foreach ($line in $lines) {
        # Skip empty lines and comments
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }
        
        # Convert gitignore pattern to regex-friendly format
        $pattern = $trimmed
        
        # Handle negation patterns (skip for simplicity)
        if ($pattern.StartsWith('!')) {
            continue
        }
        
        # Remove leading slash (means root directory)
        $isRooted = $pattern.StartsWith('/')
        if ($isRooted) {
            $pattern = $pattern.Substring(1)
        }
        
        # Handle directory patterns (ending with /)
        $isDirOnly = $pattern.EndsWith('/')
        if ($isDirOnly) {
            $pattern = $pattern.TrimEnd('/')
        }
        
        $patterns += @{
            Original = $trimmed
            Pattern = $pattern
            IsRooted = $isRooted
            IsDirOnly = $isDirOnly
        }
    }
    
    return $patterns
}

function Test-ShouldIgnore {
    param(
        [string]$relativePath,
        [bool]$isDirectory
    )
    
    if ($global:IgnorePatterns.Count -eq 0) {
        return $false
    }
    
    # Normalize path separators
    $testPath = $relativePath.Replace('\', '/')
    
    foreach ($patternObj in $global:IgnorePatterns) {
        $pattern = $patternObj.Pattern
        $isRooted = $patternObj.IsRooted
        $isDirOnly = $patternObj.IsDirOnly
        
        # If pattern is directory-only but item is a file, skip
        if ($isDirOnly -and -not $isDirectory) {
            continue
        }
        
        # Convert gitignore wildcards to regex patterns
        $wildcardPattern = $pattern.Replace('.', '\.').Replace('*', '.*').Replace('?', '.')
        
        # Test if pattern matches
        $matched = $false
        
        if ($isRooted) {
            # Pattern is rooted - must match from start
            $matched = $testPath -match "^$wildcardPattern(/|$)"
        } else {
            # Pattern can match anywhere in path
            $matched = ($testPath -match "(^|/)$wildcardPattern(/|$)") -or 
                       ($testPath -match "^$wildcardPattern$")
        }
        
        if ($matched) {
            return $true
        }
    }
    
    return $false
}

function Write-MarkdownTree {
    param (
        [string]$path,
        [int]$depth = 0,
        [string]$relativePath = ""
    )

    if (-not (Test-Path $path)) { return }

    $items = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | 
             Sort-Object -Property PSIsContainer, Name

    foreach ($item in $items) {
        # Build relative path for ignore checking
        $currentRelPath = if ($relativePath) { 
            "$relativePath/$($item.Name)" 
        } else { 
            $item.Name 
        }
        
        # Check if this item should be ignored
        if (Test-ShouldIgnore -relativePath $currentRelPath -isDirectory $item.PSIsContainer) {
            continue
        }

        $indent = '  ' * $depth

        if ($item.PSIsContainer) {
            $global:FolderCount++
            $line = "$indent- $($item.Name)/"
            $global:MarkdownLines += $line
            
            # Recurse into subdirectories
            Write-MarkdownTree -path $item.FullName -depth ($depth + 1) -relativePath $currentRelPath
        } else {
            $global:FileCount++
            $line = "$indent- $($item.Name)"
            $global:MarkdownLines += $line
        }
    }
}

# Parse .gitignore patterns
$global:IgnorePatterns = Parse-GitIgnore -gitignorePath $GitIgnorePath

# Add manual ignores if any
foreach ($manualPattern in $ManualIgnores) {
    if (-not [string]::IsNullOrWhiteSpace($manualPattern)) {
        $trimmed = $manualPattern.Trim()
        $isDirOnly = $trimmed.EndsWith('/')
        if ($isDirOnly) {
            $trimmed = $trimmed.TrimEnd('/')
        }
        
        $global:IgnorePatterns += @{
            Original = $manualPattern
            Pattern = $trimmed
            IsRooted = $false
            IsDirOnly = $isDirOnly
        }
    }
}

if ($global:IgnorePatterns.Count -gt 0) {
    Write-Host "📋 Loaded $($global:IgnorePatterns.Count) ignore patterns"
}

# Build structure from project root
Write-Host "📂 Building project structure..."
Write-MarkdownTree -path $ProjectRoot -depth 0

# Write Markdown
$global:MarkdownLines | Out-File -FilePath $OutputFile -Encoding UTF8
$global:MarkdownLines | ForEach-Object { Write-Host $_ }

# Summary
Write-Host ""
Write-Host "✅ $($global:FileCount) files listed across $($global:FolderCount) folders." -ForegroundColor Green
Write-Host "📄 Markdown saved to: $OutputFile" -ForegroundColor Cyan