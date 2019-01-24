using System;
using UnityEditor.ShaderGraph.Drawing.Slots;
using UnityEngine.UIElements;
using UnityEditor.Graphing;
using UnityEngine;

namespace UnityEditor.ShaderGraph
{
    [Serializable]
    class BakedGIMaterialSlot : Vector3MaterialSlot
    {
        public BakedGIMaterialSlot()
        {}

        public BakedGIMaterialSlot(int slotId, string displayName, string shaderOutputName,
                                    ShaderStageCapability stageCapability = ShaderStageCapability.All, bool hidden = false)
            : base(slotId, displayName, shaderOutputName, SlotType.Input, Vector3.zero, stageCapability, hidden: hidden)
        {}

        public override VisualElement InstantiateControl()
        {
            return new LabelSlotControlView("Baked GI");
        }
    }
}
