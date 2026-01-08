#!/bin/bash
set -e

# Log output
exec > >(tee /var/log/boomi-install.log) 2>&1
echo "Starting Boomi Atom installation..."

# Update system and install dependencies
yum update -y
yum install -y java-1.8.0-openjdk

# Format and mount EBS volume
while [ ! -e /dev/nvme1n1 ] && [ ! -e /dev/xvdf ]; do
  echo "Waiting for EBS volume to attach..."
  sleep 5
done

# Determine device name (NVMe or traditional)
if [ -e /dev/nvme1n1 ]; then
  DEVICE=/dev/nvme1n1
else
  DEVICE=/dev/xvdf
fi

# Check if already formatted
if ! blkid $DEVICE; then
  echo "Formatting $DEVICE as XFS..."
  mkfs -t xfs $DEVICE
fi

# Mount volume
mkdir -p ${boomi_install_dir}
echo "$DEVICE ${boomi_install_dir} xfs defaults,noatime 0 0" >> /etc/fstab
mount -a

# Set ownership
chown -R ec2-user:ec2-user ${boomi_install_dir}

# Download Boomi installer
echo "Downloading Boomi installer..."
cd /tmp
wget -q https://platform.boomi.com/atom/atom_install64.sh
chmod +x atom_install64.sh

# Install Boomi Atom
echo "Installing Boomi Atom..."
./atom_install64.sh -q console \
  -VinstallToken="${boomi_install_token}" \
  -VatomName="${atom_name}" \
  -VaccountId="${boomi_account_id}" \
  -dir "${boomi_install_dir}"

# Create systemd service
cat > /etc/systemd/system/boomi-atom.service << 'EOF'
[Unit]
Description=Dell Boomi Atom
After=network.target
RequiresMountsFor=${boomi_install_dir}

[Service]
Type=forking
User=ec2-user
Restart=always
ExecStart=${boomi_install_dir}Atom_${atom_name}/bin/atom start
ExecStop=${boomi_install_dir}Atom_${atom_name}/bin/atom stop
ExecReload=${boomi_install_dir}Atom_${atom_name}/bin/atom restart

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable boomi-atom
systemctl start boomi-atom

echo "Boomi Atom installation complete!"
