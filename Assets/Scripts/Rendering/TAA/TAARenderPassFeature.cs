using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TAARenderPassFeature : ScriptableRendererFeature
{
	#region member
	TAARenderPass pass;
	public Setting setting = new Setting();
	#endregion

	public override void Create()
	{
		pass = new TAARenderPass(this);
		pass.renderPassEvent = setting.evt;
	}

	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		pass.src = renderer.cameraColorTarget;
		renderingData.cameraData.camera.ResetProjectionMatrix();
		renderer.EnqueuePass(pass);
	}

	public override void OnCameraPreCull(ScriptableRenderer renderer, in CameraData cameraData)
	{
		//Debug.Log("before cull");
		
		
	}

	#region class
	class TAARenderPass : ScriptableRenderPass
	{
		public RenderTargetIdentifier src;
		/// <summary>
		/// 长度为9的Halton数列: https://baike.baidu.com/item/Halton%20sequence/16697800
		/// </summary>
		/// <value>长度为9的Halton数列</value>
		private Vector2[] HaltonSequence9 = new Vector2[]
		{
			new Vector2(0.5f, 1.0f / 3f),
			new Vector2(0.25f, 2.0f / 3f),
			new Vector2(0.75f, 1.0f / 9f),
			new Vector2(0.125f, 4.0f / 9f),
			new Vector2(0.625f, 7.0f / 9f),
			new Vector2(0.375f, 2.0f / 9f),
			new Vector2(0.875f, 5.0f / 9f),
			new Vector2(0.0625f, 8.0f / 9f),
			new Vector2(0.5625f, 1.0f / 27f),
		};
		private int index = 0;//当前halton序号
		private TAARenderPassFeature ft;
		private const string shaderName = "TAA";
		private Material material;
		
		private int[] m_HistoryTextures = new int[2];
		
		RenderTargetIdentifier _renderTargetIdentifier;
		
		private int FrameCount = 0;
		private Vector2 _Jitter;
		bool m_ResetHistory = true;
	
		/// <summary>
		/// 上一帧图像
		/// </summary>
		private RenderTexture preRT;
		private Camera camera;

		public TAARenderPass(TAARenderPassFeature f)
		{
			ft = f;
		}

		public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
		{
			if (material == null)
			{
				Shader shader = Shader.Find(shaderName);
				if (shader == null) return;
				material = CoreUtils.CreateEngineMaterial(shader);
			}

			//camera.useJitteredProjectionMatrixForTransparentRendering = true;
			
			//camera shake
			/*camera = renderingData.cameraData.camera;
			camera.ResetProjectionMatrix();
			Matrix4x4 projectionMatrix = camera.projectionMatrix;
			Vector2 jitter = new Vector2((HaltonSequence9[index].x - 0.5f) / camera.pixelWidth, (HaltonSequence9[index].y - 0.5f) / camera.pixelHeight);
			jitter *= ft.setting.jitter;
			projectionMatrix.m02 -= jitter.x * 2;
			projectionMatrix.m12 -= jitter.y * 2;
			camera.projectionMatrix = projectionMatrix;
			index = (index + 1) % 9;*/
			
			camera = renderingData.cameraData.camera;
			var proj = camera.projectionMatrix;
		
			camera.nonJitteredProjectionMatrix = proj;
			FrameCount++;
			var Index = FrameCount % 8;
			_Jitter = new Vector2(
				(HaltonSequence9[Index].x - 0.5f) / camera.pixelWidth,
				(HaltonSequence9[Index].y - 0.5f) / camera.pixelHeight);
			proj.m02 += _Jitter.x * 2;
			proj.m12 += _Jitter.y * 2;
			camera.projectionMatrix = proj;
			
			/*var cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
			cameraTargetDescriptor.enableRandomWrite = true;
			cmd.GetTemporaryRT(_renderTargetId, cameraTargetDescriptor);
			_renderTargetIdentifier = new RenderTargetIdentifier(_renderTargetId);*/
				
		}

		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
		{
			camera = renderingData.cameraData.camera;
			var source = renderingData.cameraData.renderer.cameraColorTarget;
			if (!renderingData.cameraData.postProcessEnabled) return;
			CommandBuffer cmd = CommandBufferPool.Get("shaderName");

			int w = camera.pixelWidth;
			int h = camera.pixelHeight;

			var historyRead = m_HistoryTextures[FrameCount % 2];
			
			//if (historyRead == null || historyRead.width != Screen.width || historyRead.height != Screen.height)
			//if (historyRead == null)
			{
				cmd.ReleaseTemporaryRT(historyRead);
				cmd.GetTemporaryRT(historyRead,Screen.width, Screen.height, 0,FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);
				m_HistoryTextures[FrameCount % 2] = historyRead;
				m_ResetHistory = true;
			}
			var historyWrite = m_HistoryTextures[(FrameCount + 1) % 2];
			//if (historyWrite == null || historyWrite.width != Screen.width || historyWrite.height != Screen.height)
			//if (historyWrite == null)
			{
				cmd.ReleaseTemporaryRT(historyWrite);
				cmd.GetTemporaryRT(historyRead,Screen.width, Screen.height, 0,FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);
				m_HistoryTextures[(FrameCount + 1) % 2] = historyWrite;
			}

			material.SetVector("_Jitter", _Jitter);
			//material.SetTexture("_HistoryTex", historyRead);
			cmd.SetGlobalTexture("_HistoryTex",historyRead);
			material.SetInt("_IgnoreHistory", m_ResetHistory ? 1 : 0);

			cmd.Blit(source, historyWrite, material, 0);
			cmd.Blit(historyWrite, source);
			m_ResetHistory = false;	

			//cmd.ReleaseTemporaryRT(des);
			context.ExecuteCommandBuffer(cmd);
			CommandBufferPool.Release(cmd);
		}

		public override void OnCameraCleanup(CommandBuffer cmd)
		{
			//Debug.Log("clean");
		}
	}
	[System.Serializable]
	public class Setting
	{
		public RenderPassEvent evt = RenderPassEvent.BeforeRenderingPostProcessing;
		[Header("Data")]
		[Range(0f, 5f)] public float jitter = 1f;//intensity
		[Range(0f, 1f)] public float blend = 0.05f;//blend
	}
	#endregion
}


