# 🟢 USE THE OFFICIAL WORKER BASE (Includes ComfyUI and Python Handler)
FROM runpod/worker-comfyui:5.5.1-base

USER root

# =======================================================
# 1. SYSTEM DEPENDENCIES (Core & Headless Display)
# =======================================================
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    xvfb \
    xz-utils \
    libgl1 \
    libglib2.0-0 \
    libxrender1 \
    libsm6 \
    libxext6 \
    libxi6 \
    libxkbcommon-x11-0 \
    psmisc \
    && rm -rf /var/lib/apt/lists/*

# ⬇️ INSTALL BLENDER 4.1 (Essential for GPU rendering in BlenderRenderNode)
RUN wget -q https://download.blender.org/release/Blender4.1/blender-4.1.0-linux-x64.tar.xz \
    && tar -xf blender-4.1.0-linux-x64.tar.xz -C /usr/local/ \
    && mv /usr/local/blender-4.1.0-linux-x64 /usr/local/blender \
    && ln -s /usr/local/blender/blender /usr/bin/blender \
    && rm blender-4.1.0-linux-x64.tar.xz

# =======================================================
# 2. PYTHON DEPENDENCIES
# =======================================================
RUN pip install --no-cache-dir numpy pillow opencv-python-headless

# =======================================================
# 3. INSTALL REGISTRY CUSTOM NODES
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
# 4. COPY LOCAL NODES (Exactly matching NK-SERVERELESS-REPO)
# =======================================================
# 🟢 Node: BlackBackgroundScanner
COPY ComfyUI_Document_Scanner /comfyui/custom_nodes/ComfyUI_Document_Scanner

# 🟢 Node: SeamlessPatternNode
COPY ComfyUI_SeamlessPattern /comfyui/custom_nodes/ComfyUI_SeamlessPattern

# 🟢 Node: BlenderRenderNode
COPY ComfyUI_blender_render /comfyui/custom_nodes/ComfyUI_blender_render

# ✅ LINK BLENDER: Directs the node to the manual v4.1 install
RUN mkdir -p /comfyui/custom_nodes/ComfyUI_blender_render/blender && \
    ln -s /usr/bin/blender /comfyui/custom_nodes/ComfyUI_blender_render/blender/blender && \
    pip install -r /comfyui/custom_nodes/ComfyUI_blender_render/requirements.txt || true

# =======================================================
# 5. DOWNLOAD MODELS (Flux, SAM, & Scene Assets)
# =======================================================
# FLUX Encoders & VAE
RUN wget -q -O /comfyui/models/clip/t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors && \
    wget -q -O /comfyui/models/clip/clip_l.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/main/clip_l.safetensors && \
    wget -q -O /comfyui/models/vae/ae.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/ae.safetensors

# FLUX Diffusion Weights (FP8 Optimized)
RUN wget -q -O /comfyui/models/diffusion_models/flux1-dev.safetensors https://huggingface.co/yichengup/flux.1-fill-dev-OneReward/resolve/main/unet_fp8.safetensors && \
    wget -q -O /comfyui/models/diffusion_models/flux1-dev-fp8-e4m3fn.safetensors https://huggingface.co/Kijai/flux-fp8/resolve/main/flux1-dev-fp8-e4m3fn.safetensors

# Vision & Style Components
RUN wget -q -O /comfyui/models/clip_vision/sglip2-so400m-patch16-512.safetensors https://huggingface.co/google/siglip2-so400m-patch16-512/resolve/main/model.safetensors && \
    wget -q -O /comfyui/models/style_models/flux1-redux-dev.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/flux1-redux-dev.safetensors && \
    wget -q -O /comfyui/models/upscale_models/4x-UltraSharp.pth https://huggingface.co/Kim2091/UltraSharp/resolve/main/4x-UltraSharp.pth

# ✅ SEGMENTATION MODELS (For Node 253 "SegmentV2")
RUN mkdir -p /comfyui/models/sams && \
    wget -q -O /comfyui/models/sams/sam_vit_h.pth https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth && \
    mkdir -p /comfyui/models/grounding-dino && \
    wget -q -O /comfyui/models/grounding-dino/GroundingDINO_SwinT_OGC.pth https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/GroundingDINO_SwinT_OGC.pth && \
    wget -q -O /comfyui/models/grounding-dino/GroundingDINO_SwinT_OGC.cfg.py https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/GroundingDINO_SwinT_OGC.cfg.py

# ✅ ASSETS: Blender File (Matches ID 325 "file.blend")
RUN mkdir -p /comfyui/input && \
    wget -q -O /comfyui/input/file.blend https://huggingface.co/Srivarshan7/my-assets/resolve/b61a31e/file.blend

# =======================================================
# 6. STARTUP (Xvfb Virtual Display for Headless Rendering)
# =======================================================
ENV DISPLAY=:99
# Starts Xvfb to prevent Blender rendering crashes
CMD Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 & sleep 5 && python -u /rp_handler.py
