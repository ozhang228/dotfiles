# Usage: pdflock <file.pdf | directory>
# 
# Encrypts a PDF file or all PDFs in a directory with a password using AES-256 encryption.
# 
# Arguments:
#   file.pdf          - Single PDF file to encrypt (will be renamed to file.locked.pdf)
#   directory         - Directory containing PDFs to encrypt (skips .locked.pdf files)
# 
# Examples:
#   pdflock document.pdf              # Encrypt single file
#   pdflock ~/Documents/              # Encrypt all PDFs in directory
# 
# Notes:
#   - Prompts for password twice (must match to confirm)
#   - Original file is deleted after successful encryption
#   - Output filename: originalname.locked.pdf
#   - Already-locked files (.locked.pdf) are automatically skipped
#   - Requires: qpdf

function pdflock
    if test (count $argv) -ne 1
        echo 'Usage: pdflock <file.pdf | directory>'
        return 1
    end
    
    # Prompt once
    read -s -p "Enter password: " pw
    echo
    read -s -p "Confirm password: " pw2
    echo
    
    if test "$pw" != "$pw2"
        echo "Error: passwords do not match"
        return 1
    end
    
    # Helper function
    function _pdflock_one
        set -l in "$argv[1]"
        set -l out (string replace '.pdf' '.locked.pdf' $in)
        qpdf --encrypt "$pw" "$pw" 256 -- "$in" "$out" && rm -f -- "$in"
    end
    
    if test -d "$argv[1]"
        for f in "$argv[1]"/*.pdf
            if string match -q '*.locked.pdf' $f
                continue
            end
            echo "Locking: $f"
            _pdflock_one "$f" || return 1
        end
    else
        if not string match -q '*.pdf' "$argv[1]"
            echo "Error: not a PDF"
            return 1
        end
        _pdflock_one "$argv[1]"
    end
end
