using System;
using System.Collections.Generic;
using UnityEngine;

namespace UnityEditor.ShaderGraph
{
    //enum NewExponentialBase
    //{
    //    BaseE,
    //    Base2
    //};

    class NewExponentialNode : IShaderNodeType
    {
        InputPortRef m_InPort;
        OutputPortRef m_OutPort;

        public void Setup(ref NodeSetupContext context)
        {
            m_InPort = context.CreateInputPort(0, "In", PortValue.DynamicVector(0f));
            m_OutPort = context.CreateOutputPort(1, "Out", PortValueType.DynamicVector);

            var type = new NodeTypeDescriptor
            {
                path = "Math/Advanced",
                name = "New Exponential",
                inputs = new List<InputPortRef> { m_InPort },
                outputs = new List<OutputPortRef> { m_OutPort }
            };

            context.CreateType(type);
        }

        HlslSourceRef m_Source;

        public void OnChange(ref NodeTypeChangeContext context)
        {
            if (!m_Source.isValid)
            {
                m_Source = context.CreateHlslSource("Packages/com.unity.shadergraph/Editor/Data/Nodes/Math/Advanced/Math_Advanced.hlsl");
            }

            foreach (var node in context.addedNodes)
            {
                context.SetHlslFunction(node, new HlslFunctionDescriptor
                {
                    source = m_Source,
                    name = "Unity_Exponential",
                    arguments = new HlslArgumentList { m_InPort },
                    returnValue = m_OutPort
                });
            }

            //foreach (var node in context.modifiedNodes)
            //{
            //    var data = (ExponentialData)context.GetData(node);
            //    if (context.WasControlModified(data.expBaseControl))
            //    {
            //        data.expBase = context.GetControlValue(data.expBaseControl);
            //        context.SetHlslValue(data.expBaseValue, data.expBase);
            //    }
            //}
        }

        //[Serializable]
        //class ExponentialData
        //{
        //    public NewExponentialBase expBase;

        //    [NonSerialized]
        //    public HlslValueRef expBaseValue;

        //    [NonSerialized]
        //    public ControlRef expBaseControl;
        //}

    }

}