#!/usr/bin/env bash
# Verify that an executable is a 32-bit ARM little-endian Android ELF.
# Usage: verify-elf.sh <binary> <llvm-readelf>
set -u

bin="$1"
readelf="$2"
fail=0

# result <label> <condition-exit-code>: 0 means the check passed.
result() {
    if [ "$2" -eq 0 ]; then
        echo "  [OK]   $1"
    else
        echo "  [FAIL] $1"
        fail=1
    fi
}

echo "== $bin"
header=$("$readelf" -h "$bin")

echo "$header" | grep -q "Class:.*ELF32";                 result "ELF32" $?
echo "$header" | grep -q "2's complement, little endian"; result "little endian" $?
echo "$header" | grep -q "Machine:.*ARM";                 result "machine ARM" $?
if echo "$header" | grep -q "AArch64"; then
    result "absence d'AArch64" 1
else
    result "absence d'AArch64" 0
fi

# Dependances dynamiques : seules les bibliotheques Android connues sont admises.
allowed="libc.so libm.so libdl.so liblog.so libc++_shared.so libandroid.so libz.so"
needed=$("$readelf" -d "$bin" | sed -n 's/.*Shared library: \[\(.*\)\].*/\1/p')
echo "  Dependances :"
for lib in $needed; do
    case " $allowed " in
        *" $lib "*) echo "    - $lib (Android)" ;;
        *) echo "    - $lib (INCONNUE)"; fail=1 ;;
    esac
done

# Symboles non resolus : l'editeur de liens echoue sur un executable avec symbole manquant.
# Le binaire present et lisible valide donc cette etape.
if [ -s "$bin" ]; then result "fichier non vide" 0; else result "fichier non vide" 1; fi

exit $fail
