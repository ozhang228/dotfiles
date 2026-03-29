# Usage: pdfunlock <file.locked.pdf | directory>
# 
# Decrypts a password-protected PDF file or all encrypted PDFs in a directory.
# 
# Arguments:
#   file.locked.pdf   - Single encrypted PDF file (will be renamed to file.pdf)
#   directory         - Directory containing .locked.pdf files to decrypt
# 
# Examples:
#   pdfunlock document.locked.pdf     # Decrypt single file
#   pdfunlock ~/Documents/            # Decrypt all .locked.pdf files
# 
# Notes:
#   - Prompts for password once
#   - Original encrypted file is deleted after successful decryption
#   - Output filename: originalname.pdf
#   - Only processes files ending in .locked.pdf
#   - Requires: qpdf

function pdfunlock
    if test (count $argv) -ne 1
        echo 'Usage: pdfunlock <file.locked.pdf | directory>'
        return 1
    end
    
    read -s -p "Enter password: " pw
    echo
    
    # Helper function
    function _pdfunlock_one
        set -l in "$argv[1]"
        set -l out (string replace '.locked.pdf' '.pdf' $in)
        qpdf --decrypt --password="$pw" -- "$in" "$out" && rm -f -- "$in"
    end
    
    if test -d "$argv[1]"
        for f in "$argv[1]"/*.locked.pdf
            echo "Unlocking: $f"
            _pdfunlock_one "$f" || return 1
        end
    else
        if not string match -q '*.locked.pdf' "$argv[1]"
            echo "Error: expected .locked.pdf"
            return 1
        end
        _pdfunlock_one "$argv[1]"
    end
end
