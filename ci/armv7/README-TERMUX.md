# llama.cpp ARMv7 pour Termux

Ce paquet contient des executables llama.cpp compiles en **ARM 32 bits** (`armeabi-v7a`, Android API 24).
Il ne fonctionne pas sur un systeme ARM 64 bits en mode 64 bits : il faut un Termux 32 bits ou un noyau/userspace 32 bits (par exemple `uname -m` renvoie `armv7l` ou `armv8l`).

## 1. Telecharger

Telechargez l'archive depuis l'onglet **Actions** de votre fork, dans l'artifact `armv7-minimal`
(fichier `llama.cpp-armv7-release.zip`).

## 2. Extraire dans Termux

```sh
pkg install -y unzip
cd ~
unzip llama.cpp-armv7-release.zip
cd llama.cpp-armv7-minimal
chmod +x bin/*
```

## 3. Verifier l'architecture

```sh
uname -m                   # attendu : armv7l ou armv8l
./termux-test.sh           # verifie les executables et lance --version
```

Pour verifier le format ELF a la main (optionnel) :

```sh
pkg install -y binutils-is-llvm 2>/dev/null || true
readelf -h bin/llama-cli | grep -E "Class|Machine|Data"
```

Attendu : `ELF32`, `ARM`, `little endian`.

## 4. Verifier les bibliotheques

```sh
readelf -d bin/llama-cli | grep NEEDED
```

Les bibliotheques attendues sont `libc.so`, `libm.so`, `libdl.so`, `liblog.so` et `libc++_shared.so`. Elles sont fournies par Android.

Si `libc++_shared.so` manque :

```sh
find /system -name libc++_shared.so 2>/dev/null | head -1
```

## 5. Lancer avec un modele GGUF

Copiez un modele GGUF petit (quantifie, par exemple Q4_0 ou Q4_K_M) dans `~/models/`, puis :

```sh
./bin/llama-cli -m ~/models/modele.gguf -p "Bonjour" -n 32 -t 4
```

Avec RAM limitee (3 Go), preferez un modele de moins de 1 Go et un contexte court :

```sh
./bin/llama-cli -m ~/models/modele.gguf -c 512 -n 64 -t 4 --no-mmap
```

## 6. Lancer llama-server

```sh
./bin/llama-server -m ~/models/modele.gguf -c 512 --host 127.0.0.1 --port 8080 -t 4
```

Depuis un second terminal Termux :

```sh
curl http://127.0.0.1:8080/health
```

Pour l'API de completion :

```sh
curl http://127.0.0.1:8080/completion -d '{"prompt":"Bonjour","n_predict":32}'
```

## 7. Erreurs Android courantes

| Erreur | Cause probable | Solution |
|---|---|---|
| `Permission denied` | Fichier non executable | `chmod +x bin/*` |
| `not found` alors que le fichier existe | Mauvaise architecture ou bibliotheque absente | Verifier `uname -m` et la section 4 |
| `CANNOT LINK EXECUTABLE ... libc++_shared.so` | Bibliotheque C++ non trouvee | Voir section 4 |
| `Exec format error` | Binaire 64 bits sur un systeme 32 bits (ou l'inverse) | Utiliser l'archive ARMv7 uniquement |
| `Illegal instruction` | Instruction non supportee par le CPU | Utiliser la variante `minimal` (sans NEON) |
| `Killed` / arret brutal | Manque de RAM | Modele plus petit, `-c 512`, `--no-mmap` |
| `Segmentation fault` | Modele corrompu ou incompatible | Verifier le modele et la somme SHA256 |

Verifiez l'integrite de l'archive :

```sh
sha256sum -c SHA256SUMS
```
