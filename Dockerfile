# 🟢 USE THE OFFICIAL WORKER BASE
FROM runpod/worker-comfyui:5.5.1-base

USER root

# =======================================================
# 1. SYSTEM DEPENDENCIES (Blender & Headless Display)
# =======================================================
RUN apt-get update && apt-get install -y \
    wget unzip xvfb xz-utils libgl1 libglib2.0-0 \
    libxrender1 libsm6 libxext6 libxi6 libxkbcommon-x11-0 psmisc \
    && rm -rf /var/lib/apt/lists/*

# ⬇️ INSTALL BLENDER (Essential for BlenderRenderNode)
RUN wget -q https://download.blender.org/release/Blender4.1/blender-4.1.0-linux-x64.tar.xz \
    && tar -xf blender-4.1.0-linux-x64.tar.xz -C /usr/local/ \
    && mv /usr/local/blender-4.1.0-linux-x64 /usr/local/blender \
    && ln -s /usr/local/blender/blender /usr/bin/blender \
    && rm blender-4.1.0-linux-x64.tar.xz

# =======================================================
# 2. INSTALL STANDARD CUSTOM NODES
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
# 3. COPY LOCAL NODES (Matched to NK-SERVERELESS-REPO)
# =======================================================
COPY ComfyUI_Document_Scanner /comfyui/custom_nodes/ComfyUI_Document_Scanner
COPY ComfyUI_SeamlessPattern /comfyui/custom_nodes/ComfyUI_SeamlessPattern
COPY ComfyUI_blender_render /comfyui/custom_nodes/ComfyUI_blender_render

# ✅ LINK BLENDER & Install requirements for the 3D Node
RUN mkdir -p /comfyui/custom_nodes/ComfyUI_blender_render/blender && \
    ln -s /usr/bin/blender /comfyui/custom_nodes/ComfyUI_blender_render/blender/blender && \
    pip install -r /comfyui/custom_nodes/ComfyUI_blender_render/requirements.txt || true

# =======================================================
# 4. DOWNLOAD MODELS
# =======================================================
# FLUX Core
RUN wget -q -O /comfyui/models/clip/t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors && \
    wget -q -O /comfyui/models/clip/clip_l.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/main/clip_l.safetensors && \
    wget -q -O /comfyui/models/vae/ae.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/ae.safetensors && \
    wget -q -O /comfyui/models/diffusion_models/flux1-dev.safetensors https://huggingface.co/yichengup/flux.1-fill-dev-OneReward/resolve/main/unet_fp8.safetensors

# Vision & SAM (For SegmentV2)
RUN wget -q -O /comfyui/models/clip_vision/sglip2-so400m-patch16-512.safetensors https://huggingface.co/google/siglip2-so400m-patch16-512/resolve/main/model.safetensors && \
    mkdir -p /comfyui/models/sams && \
    wget -q -O /comfyui/models/sams/sam_vit_h.pth https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth

# ✅ BLEND FILE (Required for ID 325)
RUN mkdir -p /comfyui/input && \
    wget -q -O /comfyui/input/file.blend https://huggingface.co/Srivarshan7/my-assets/resolve/b61a31e/file.blend

# =======================================================
# 5. STARTUP COMMAND
# =======================================================
ENV DISPLAY=:99
CMD Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 & sleep 5 && python -u /rp_handler.py
