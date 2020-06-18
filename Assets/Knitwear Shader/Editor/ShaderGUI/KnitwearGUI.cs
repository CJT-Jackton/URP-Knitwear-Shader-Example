using UnityEngine;
using UnityEngine.Rendering;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    public static class KnitwearGUI
    {
        public static class Styles
        {
            public static GUIContent knitwearMapText =
                new GUIContent("Knitwear Map", "Sets a Texture map to use for knitwear texture.");

            public static GUIContent knitwearDivisionText =
                new GUIContent("Division", "Controls the scaling of the knitwear texture.");

            public static GUIContent knitwearAspectText =
                new GUIContent("Aspect", "Controls the rectangle aspect ratio of the knitwear texture.");

            public static GUIContent knitwearShearText =
                new GUIContent("Shear", "Controls the shear amount on vertical direction of the knitwear texture.");

            public static GUIContent knitwearDistortionText =
                new GUIContent("Distortion", "When enabled, the knitwear texture distortion randomly.");

            public static GUIContent knitwearDistortionStrengthText =
                new GUIContent("Strength", "Controls the distortion amount of the knitwear texture.");
        }

        public struct KnitwearProperties
        {
            public MaterialProperty knitwearMap;
            public MaterialProperty knitwearDivision;
            public MaterialProperty knitwearAspect;
            public MaterialProperty knitwearShear;
            public MaterialProperty knitwearDistortion;
            public MaterialProperty knitwearDistortionStrength;

            public KnitwearProperties(MaterialProperty[] properties)
            {
                knitwearMap = BaseShaderGUI.FindProperty("_KnitwearMap", properties, false);
                knitwearDivision = BaseShaderGUI.FindProperty("_KnitwearDivision", properties, false);
                knitwearAspect = BaseShaderGUI.FindProperty("_KnitwearAspect", properties, false);
                knitwearShear = BaseShaderGUI.FindProperty("_KnitwearShear", properties, false);
                knitwearDistortion = BaseShaderGUI.FindProperty("_KnitwearDistortion", properties, false);
                knitwearDistortionStrength = BaseShaderGUI.FindProperty("_KnitwearDistortionStrength", properties, false);
            }
        }

        public static void DoKnitwearArea(KnitwearProperties properties, MaterialEditor materialEditor)
        {
            materialEditor.TexturePropertySingleLine(Styles.knitwearMapText, properties.knitwearMap, null);

            EditorGUI.indentLevel++;
            materialEditor.ShaderProperty(properties.knitwearDivision, Styles.knitwearDivisionText);
            materialEditor.ShaderProperty(properties.knitwearAspect, Styles.knitwearAspectText);
            materialEditor.ShaderProperty(properties.knitwearShear, Styles.knitwearShearText);

            EditorGUI.BeginChangeCheck();
            bool distortion = properties.knitwearDistortion.floatValue != 0.0f;
            distortion = EditorGUILayout.Toggle(Styles.knitwearDistortionText, distortion);
            if (EditorGUI.EndChangeCheck())
                properties.knitwearDistortion.floatValue = distortion ? 1.0f : 0.0f;

            EditorGUI.BeginDisabledGroup(!distortion);
            EditorGUI.indentLevel++;
            materialEditor.ShaderProperty(properties.knitwearDistortionStrength, Styles.knitwearDistortionStrengthText);
            EditorGUI.indentLevel--;
            EditorGUI.EndDisabledGroup();

            EditorGUI.indentLevel--;
        }

        public static void SetMaterialKeywords(Material material)
        {
            if (material.HasProperty("_KnitwearDistortion"))
                CoreUtils.SetKeyword(material, "_KNITWEAR_DISTORTION_ON", material.GetFloat("_KnitwearDistortion") != 0.0f);
        }
    }
}
