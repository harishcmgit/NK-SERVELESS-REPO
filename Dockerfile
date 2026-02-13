# 🟢 USE THE OFFICIAL WORKER BASE (It manages the Headless Server for you)
FROM runpod/worker-comfyui:5.5.1-base

# =======================================================
# 1. SYSTEM DEPENDENCIES
# =======================================================
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    blender \
    libgl1 \
    libglib2.0-0 \
    libxrender1 \
    libsm6 \
    libxext6 \
    libjpeg-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

# =======================================================
# 2. PYTHON DEPENDENCIES
# =======================================================
RUN pip install --no-cache-dir numpy pillow opencv-python-headless

# =======================================================
# 3. INSTALL CUSTOM NODES (Standard)
# =======================================================
RUN comfy node install --exit-on-fail comfyui_essentials@1.1.0 --mode remote
RUN comfy node install --exit-on-fail ComfyUI_Comfyroll_CustomNodes
RUN comfy node install --exit-on-fail comfyui-kjnodes@1.2.9
RUN comfy node install --exit-on-fail was-node-suite-comfyui@1.0.2
RUN comfy node install --exit-on-fail comfyui-easy-use@1.3.6
RUN comfy node install --exit-on-fail ComfyUI-TiledDiffusion
RUN comfy node install --exit-on-fail comfyui-inpaint-cropandstitch@3.0.2
RUN comfy node install --exit-on-fail rgthree-comfy@1.0.2512112053
RUN comfy node install --exit-on-fail comfyui-rmbg@3.0.0
RUN comfy node install --exit-on-fail comfyui_layerstyle@2.0.38
RUN comfy node install --exit-on-fail ComfyUI_AdvancedRefluxControl

# =======================================================
# 4. COPY LOCAL CUSTOM NODES (Use your folder names)
# =======================================================
# 🟢 Node: BlackBackgroundScanner
COPY ComfyUI_Document_Scanner /comfyui/custom_nodes/ComfyUI_Document_Scanner

# 🟢 Node: SeamlessPatternNode
COPY ComfyUI_SeamlessPattern /comfyui/custom_nodes/ComfyUI_SeamlessPattern

# 🟢 Node: BlenderRenderNode
COPY ComfyUI_blender_render /comfyui/custom_nodes/ComfyUI_blender_render
# =======================================================
# 5. DOWNLOAD MODELS (Using wget)
# =======================================================
# FLUX T5XXL
RUN wget -O /comfyui/models/clip/t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors

# FLUX CLIP-L
RUN wget -O /comfyui/models/clip/clip_l.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/main/clip_l.safetensors

# FLUX VAE
RUN wget -O /comfyui/models/vae/ae.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/ae.safetensors

# SigLIP2 Vision
RUN wget -O /comfyui/models/clip_vision/sglip2-so400m-patch16-512.safetensors https://huggingface.co/google/siglip2-so400m-patch16-512/resolve/main/model.safetensors

# FLUX Redux Style
RUN wget -O /comfyui/models/style_models/flux1-redux-dev.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/flux1-redux-dev.safetensors

# FLUX UNet (Renamed for your workflow)
RUN wget -O /comfyui/models/diffusion_models/flux1-dev.safetensors https://huggingface.co/yichengup/flux.1-fill-dev-OneReward/resolve/main/unet_fp8.safetensors

# UltraSharp
RUN wget -O /comfyui/models/upscale_models/4x-UltraSharp.pth https://huggingface.co/Kim2091/UltraSharp/resolve/main/4x-UltraSharp.pth

# Extra Flux FP8
RUN wget -O /comfyui/models/diffusion_models/flux1-dev-fp8-e4m3fn.safetensors https://huggingface.co/Kijai/flux-fp8/resolve/main/flux1-dev-fp8-e4m3fn.safetensors

# BLEND File
RUN wget -O /comfyui/input/file.blend https://huggingface.co/Srivarshan7/my-assets/resolve/b61a31e/file.blend

# ⚠️ CRITICAL: DO NOT ADD "CMD python handler.py"
# The base image already has the correct startup command.
