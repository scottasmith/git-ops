#!/bin/sh

export KEY_NAME="homecluster.home.lan"
export KEY_COMMENT="flux secrets"

PRE_KEY_FP=$(gpg --with-colons --fingerprint --list-secret-keys "${KEY_NAME}" 2>/dev/null | awk -F: '$1 == "fpr" {print $10;}' | head -n 1)

if [ "x${PRE_KEY_FP}" = "x" ]; then
    echo "Creating a new gpg key"
    gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Comment: ${KEY_COMMENT}
Name-Real: ${KEY_NAME}
EOF
fi

KEY_FP=$(gpg --with-colons --fingerprint --list-secret-keys "${KEY_NAME}" | awk -F: '$1 == "fpr" {print $10;}' | head -n 1)

printf "Secret key\n"

gpg --export-secret-keys --armor "${KEY_FP}"

printf "\nKubernetes secret\n"

gpg --export-secret-keys --armor "${KEY_FP}" | \
kubectl create secret generic sops-gpg \
  --namespace=flux-system \
  --from-file=sops.asc=/dev/stdin \
  --dry-run=client \
  -o yaml

#gpg --delete-secret-keys "${KEY_FP}"

printf "\nPut these somewhere safe!!!\n"

cat <<EOF > ./.sops.yaml
creation_rules:
  - path_regex: .*.yaml
    encrypted_regex: ^(data|stringData)$
    pgp: ${KEY_FP}
EOF
