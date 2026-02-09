#!/bin/bash

# Konfigurasi Timezone
echo "⏰ Preparing timezone..."
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# Install Dependencies
echo "📦 Installing dependencies..."
sudo apt update -y
sudo apt install bc cpio flex bison aptitude git python-is-python3 tar aria2 perl wget curl lz4 libssl-dev -y

# Clone Toolchains
echo "🔧 Cloning toolchains..."
mkdir clang && cd clang && curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" && chmod a+x antman && ./antman -S && ./antman --patch=glibc && cd ..
git clone https://github.com/greenforce-project/gcc-arm64 -b main --depth=1 gcc64
git clone https://github.com/greenforce-project/gcc-arm -b main --depth=1 gcc32

# Setup Environment
echo "⚙️ Setting up environment..."
export BUILD_TIME=$(TZ=Asia/Jakarta date '+%d%m%Y-%H%M')
export CLANG_PATH=$(pwd)/clang
export GCC64_PATH=$(pwd)/gcc64
export GCC32_PATH=$(pwd)/gcc32

# Clone MambooSU
echo "📥 Cloning KernelSU-Next..."
curl -LSs "https://raw.githubusercontent.com/Mr-Morat/KernelSU-Next/legacy/kernel/setup.sh" | bash -s legacy

# Set Build Date
echo "📅 Setting build date..."
export BUILD_DATE="$(TZ=Asia/Jakarta date '+%b %d %Y')"

# Build Kernel
echo "🛠️ Building Kernel..."
export ARCH=arm64
export PATH="$CLANG_PATH/bin:$GCC64_PATH/bin:$GCC32_PATH/bin:$PATH"
export KBUILD_BUILD_USER=StriXCore
export KBUILD_BUILD_HOST=ExoticaX
export KBUILD_COMPILER_STRING="$$CLANG_PATH/clang"
export CFLAGS_EXTRA="-DBUILD_DATE=$BUILD_DATE"
make O=out ARCH=arm64 vendor/sweet_defconfig
make -j$(nproc --all) O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 CC=clang \
  CLANG_TRIPLE=$CLANG_PATH/aarch64-linux-gnu- \
  CROSS_COMPILE=$GCC64_PATH/bin/aarch64-elf- \
  CROSS_COMPILE_ARM32=$GCC32_PATH/bin/arm-eabi-

# Save Configuration
mv out/.config out/sweet_defconfig.txt

# Clone Anykernel3 & Zip
echo "📂 Cloning Anykernel3 and preparing zip..."
git clone --depth=1 https://github.com/Mr-Morat/anykernel3 -b StriXotic AnyKernel3
cp out/arch/arm64/boot/Image.gz AnyKernel3/Image.gz
cp out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img
cp out/arch/arm64/boot/dtb.img AnyKernel3/dtb.img
cd AnyKernel3
zip -r "../StriXotic-AOSP-${BUILD_TIME}.zip" *
