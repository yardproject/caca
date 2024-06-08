#!/bin/bash

# Warna-warna untuk pesan
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

# Header
echo -e "${YELLOW}"
echo -e "===================================="
echo -e "        PEMBAHARUAN MANUAL          "
echo -e "          CA Certificate            "
echo -e "       88NUMB || AtaLioMego         "
echo -e "===================================="
echo -e "${NC}"


check_certificate_status() {
    status=$(acme.sh --list | grep "$1")
    if [[ -n "$status" ]]; then
        if echo "$status" | grep -q "Renew"; then
            echo "Sertifikat untuk domain $1 perlu diperbarui."
            return 0
        else
            echo "Sertifikat untuk domain $1 sudah diterbitkan."
            return 1
        fi
    else
        echo "Tidak ada informasi sertifikat untuk domain $1."
        return 2
    fi
}

check_txt_record() {
    echo "Memeriksa TXT record untuk domain: $1"
    while true; do
        if dig +short TXT "$1" | grep -q "ACME Challenge"; then
            echo "TXT record ditemukan untuk domain: $1"
            break
        else
            echo "Menunggu TXT record untuk domain: $1"
            sleep 5
        fi
    done
}

configure_nginx() {
    echo "Konfigurasi Nginx untuk domain: $1"
    if [[ -f "/etc/nginx/sites-available/$1" ]]; then
        echo "File konfigurasi sudah ada. Memperbarui konfigurasi."
        sed -i "s/\(ssl_certificate\s\+\).*;/\1\/etc\/acme.sh\/$1\/fullchain.cer;/" "/etc/nginx/sites-available/$1"
        sed -i "s/\(ssl_certificate_key\s\+\).*;/\1\/etc\/acme.sh\/$1\/$1.key;/" "/etc/nginx/sites-available/$1"
    else
        echo "File konfigurasi belum ada. Membuat konfigurasi baru."
        cat << EOF > "/etc/nginx/sites-available/$1"
server {
    listen 443 ssl;
    server_name $1;

    ssl_certificate /etc/acme.sh/$1/fullchain.cer;
    ssl_certificate_key /etc/acme.sh/$1/$1.key;

    # Additional SSL configurations can be added here

    location / {
        # Your Nginx configuration for this domain
    }
}
EOF
    fi
    ln -s "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
    systemctl reload nginx
    echo "Konfigurasi Nginx untuk domain $1 berhasil diperbarui."
}

while true; do
    read -p "Masukkan nama domain: " domain
    check_certificate_status "$domain"
    status=$?
    case $status in
        0 )
            echo "Pilih tindakan:"
            echo "1. Perbarui sertifikat"
            echo "2. Konfigurasi Nginx"
            echo "3. Kembali"
            read -p "Pilihan: " choice
            case $choice in
                1 )
                    check_txt_record "$domain"
                    acme.sh --renew -d "$domain" \
                      --yes-I-know-dns-manual-mode-enough-go-ahead-please
                    break;;
                2 )
                    configure_nginx "$domain"
                    ;;
                3 )
                    exit;;
                * )
                    echo "Pilihan tidak valid. Silakan pilih 1, 2, atau 3.";;
            esac
            ;;
        1 )
            echo "Pilih tindakan:"
            echo "1. Lanjutkan"
            echo "2. Ubah domain"
            echo "3. Kembali"
            read -p "Pilihan: " choice
            case $choice in
                1 )
                    check_txt_record "$domain"
                    acme.sh --issue -d "$domain" --dns \
                      --yes-I-know-dns-manual-mode-enough-go-ahead-please
                    break;;
                2 )
                    ;;
                3 )
                    exit;;
                * )
                    echo "Pilihan tidak valid. Silakan pilih 1, 2, atau 3.";;
            esac
            ;;
        2 )
            echo "Lanjutkan untuk mengeluarkan sertifikat."
            check_txt_record "$domain"
            acme.sh --issue -d "$domain" --dns \
              --yes-I-know-dns-manual-mode-enough-go-ahead-please
            configure_nginx "$domain"
            break;;
    esac
done
