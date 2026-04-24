#!/bin/bash

# AWS Credentials Setup for Terraform

echo "================================"
echo "AWS Credentials Setup"
echo "================================"
echo ""
echo "You need AWS credentials to run Terraform."
echo "Get them from your AWS IAM console."
echo ""

read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -sp "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""
read -p "Enter AWS Region (default: ap-south-2): " AWS_REGION
AWS_REGION=${AWS_REGION:-ap-south-2}

echo ""
echo "Setting environment variables..."
echo ""

# Export for current session
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_REGION=$AWS_REGION

# Save to ~/.bashrc for persistence (optional)
read -p "Save credentials to ~/.bashrc for future sessions? (yes/no): " save_creds

if [ "$save_creds" = "yes" ]; then
    echo "" >> ~/.bashrc
    echo "# AWS Credentials" >> ~/.bashrc
    echo "export AWS_ACCESS_KEY_ID='$AWS_ACCESS_KEY_ID'" >> ~/.bashrc
    echo "export AWS_SECRET_ACCESS_KEY='$AWS_SECRET_ACCESS_KEY'" >> ~/.bashrc
    echo "export AWS_REGION='$AWS_REGION'" >> ~/.bashrc
    echo "✅ Credentials saved to ~/.bashrc"
else
    echo "⚠️  Credentials set for current session only."
    echo "   They will be lost when you close the terminal."
fi

echo ""
echo "✅ AWS credentials configured!"
echo ""
echo "You can now run:"
echo "  make rebuild"
echo ""
