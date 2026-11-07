#!/data/data/com.termux/files/usr/bin/sh
# Test rapide des executables llama.cpp ARMv7 dans Termux.
# Usage : ./termux-test.sh [chemin_modele.gguf]
set -u

here=$(cd "$(dirname "$0")" && pwd)
bin="$here/bin"
model="${1:-}"
fail=0

echo "== Architecture"
echo "uname -m : $(uname -m)"
case "$(uname -m)" in
    armv7l|armv8l|armv7*) echo "  [OK] systeme 32 bits" ;;
    *) echo "  [INFO] architecture inattendue pour ce paquet" ;;
esac

echo "== Executables"
for t in llama-cli llama-server llama-bench llama-quantize; do
    f="$bin/$t"
    if [ ! -f "$f" ]; then
        echo "  [ABSENT] $t"
        continue
    fi
    chmod +x "$f" 2>/dev/null
    if "$f" --version >/dev/null 2>&1; then
        echo "  [OK] $t --version"
    else
        echo "  [FAIL] $t --version"
        "$f" --version 2>&1 | tail -3
        fail=1
    fi
done

if [ -n "$model" ]; then
    echo "== Generation courte avec $model"
    if "$bin/llama-cli" -m "$model" -p "Bonjour" -n 16 -c 512 -t 4 --no-mmap 2>&1 | tail -20; then
        echo "  [INFO] execution terminee, voir la sortie ci-dessus"
    else
        fail=1
    fi
fi

exit $fail
