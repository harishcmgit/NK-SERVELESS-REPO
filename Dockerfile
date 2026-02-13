# 🟢 USE THE OFFICIAL WORKER BASE
FROM runpod/worker-comfyui:5.5.1-base

USER root

# =======================================================
# 1. SYSTEM DEPENDENCIES
# =======================================================
RUN apt-get update && apt-get install -y \
    git curl wget blender \
    libgl1 libglib2.0-0 libxrender1 libsm6 libxext6 libjpeg-dev libpng-dev \
    && rm -rf /var/lib/apt/lists/*

# =======================================================
# 2. PYTHON DEPENDENCIES
# =======================================================
RUN pip install --no-cache-dir numpy pillow opencv-python-headless

# =======================================================
# 3. INSTALL CUSTOM NODES (Standard Registry)
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
# 4. COPY LOCAL CUSTOM NODES (Matched to NK-SERVERELESS-REPO)
# =======================================================
# These MUST match the folder names in image_a37bc9.png exactly
COPY ComfyUI_Document_Scanner /comfyui/custom_nodes/ComfyUI_Document_Scanner
COPY ComfyUI_SeamlessPattern /comfyui/custom_nodes/ComfyUI_SeamlessPattern
COPY ComfyUI_blender_render /comfyui/custom_nodes/ComfyUI_blender_render

# ✅ LINK BLENDER & Install Node Requirements
RUN mkdir -p /comfyui/custom_nodes/ComfyUI_blender_render/blender && \
    ln -s /usr/bin/blender /comfyui/custom_nodes/ComfyUI_blender_render/blender/blender && \
    pip install -r /comfyui/custom_nodes/ComfyUI_blender_render/requirements.txt || true

# =======================================================
# 5. DOWNLOAD MODELS
# =======================================================
# FLUX Infrastructure
RUN wget -q -O /comfyui/models/clip/t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors && \
    wget -q -O /comfyui/models/clip/clip_l.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/main/clip_l.safetensors && \
    wget -q -O /comfyui/models/vae/ae.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/ae.safetensors && \
    wget -q -O /comfyui/models/diffusion_models/flux1-dev.safetensors https://huggingface.co/yichengup/flux.1-fill-dev-OneReward/resolve/main/unet_fp8.safetensors && \
    wget -q -O /comfyui/models/upscale_models/4x-UltraSharp.pth https://huggingface.co/Kim2091/UltraSharp/resolve/main/4x-UltraSharp.pth

# ✅ SAM & GroundingDINO (Required for Node 253)
RUN mkdir -p /comfyui/models/sams && \
    wget -q -O /comfyui/models/sams/sam_vit_h.pth https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth && \
    mkdir -p /comfyui/models/grounding-dino && \
    wget -q -O /comfyui/models/grounding-dino/GroundingDINO_SwinT_OGC.pth https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/GroundingDINO_SwinT_OGC.pth && \
    wget -q -O /comfyui/models/grounding-dino/GroundingDINO_SwinT_OGC.cfg.py https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/GroundingDINO_SwinT_OGC.cfg.py

# ✅ BLEND File (Matches your Workflow Node 325)
RUN mkdir -p /comfyui/input && \
    wget -q -O /comfyui/input/file.blend https://huggingface.co/Srivarshan7/my-assets/resolve/b61a31e/file.blend

# ⚠️ The base image (runpod/worker-comfyui) handles the start command.
