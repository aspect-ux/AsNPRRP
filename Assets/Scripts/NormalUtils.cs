using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class NormalUtils : MonoBehaviour
{
    private static string TangentMeshPath = "Assets/TangentMesh/";
    /// <summary>
    /// 对于非光滑棱角分明的图形例如正方形
    /// 容易出现断边情况，所以将法线平均化处理 并存入tangent空间
    /// </summary>
    [MenuItem("Tools/模型平均法线写入切线数据")]
    public static void WriteAverageNormalToTangentTool()
    {
        // 用于不可变形的网格
        MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        foreach (var meshFilter in meshFilters)
        {
            Mesh mesh = Object.Instantiate(meshFilter.sharedMesh);// sharedMesh用于读取网格
            WriteAverageNormalToTangent(mesh);
            CreateTangentMesh(mesh,meshFilter);
        }
        
        // 用于可变形网格
        SkinnedMeshRenderer[] skinnedMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var skinnedMeshRender in skinnedMeshRenders)
        {
            Mesh mesh = Object.Instantiate(skinnedMeshRender.sharedMesh);
            WriteAverageNormalToTangent(mesh);
            CreateTangentMesh(mesh, skinnedMeshRender);
        }
    }
    private static void WriteAverageNormalToTangent(Mesh rMesh)
    {
        Dictionary<Vector3, Vector3> tAverageNormalDic = new Dictionary<Vector3, Vector3>();
        for (int i = 0; i < rMesh.vertexCount; i++)
        {
            if (!tAverageNormalDic.ContainsKey(rMesh.vertices[i]))
            {
                tAverageNormalDic.Add(rMesh.vertices[i], rMesh.normals[i]);
            }
            else
            {
                // 多个三角形共用一个顶点 有多条法线
                //对当前顶点的所有法线进行矢量相加归一化 平滑处理
                tAverageNormalDic[rMesh.vertices[i]] = (tAverageNormalDic[rMesh.vertices[i]] + rMesh.normals[i]).normalized;
            }
        }

        // 将平均后的法线存到切线里
        Vector3[] tAverageNormals = new Vector3[rMesh.vertexCount];
        for (int i = 0; i < rMesh.vertexCount; i++)
        {
            tAverageNormals[i] = tAverageNormalDic[rMesh.vertices[i]];
        }
        
        Vector4[] tTangents = new Vector4[rMesh.vertexCount];
        for (int i = 0; i < rMesh.vertexCount; i++)
        {
            tTangents[i] = new Vector4(tAverageNormals[i].x,tAverageNormals[i].y,tAverageNormals[i].z,0);
        }

        rMesh.tangents = tTangents;
    }
    
    //在当前路径创建切线模型
    private static void CreateTangentMesh(Mesh rMesh, SkinnedMeshRenderer rSkinMeshRenders)
    {
        /*
        string[] path = AssetDatabase.GetAssetPath(rSkinMeshRenders).Split("/");
        string createPath = TangentMeshPath;
        for (int i = 0; i < path.Length - 1; i++)
        {
            createPath += path[i] + "/";
            Debug.Log("Path:"+i + path[i]);
        }*/
        
        string createPath = TangentMeshPath;
        string newMeshPath = createPath + rSkinMeshRenders.name + "_Tangent.mesh";
        Debug.Log("存储模型位置：" + newMeshPath);
        AssetDatabase.CreateAsset(rMesh, newMeshPath);
    }
    //在当前路径创建切线模型
    private static void CreateTangentMesh(Mesh rMesh, MeshFilter rMeshFilter)
    {
        string[] path = AssetDatabase.GetAssetPath(rMeshFilter).Split("/");
        string createPath = "";
        for (int i = 0; i < path.Length - 1; i++)
        {
            createPath += path[i] + "/";
        }
        string newMeshPath = createPath + rMeshFilter.name + "_Tangent.mesh";
        Debug.Log("存储模型位置：" + newMeshPath);
        AssetDatabase.CreateAsset(rMesh, newMeshPath);
    }
}
