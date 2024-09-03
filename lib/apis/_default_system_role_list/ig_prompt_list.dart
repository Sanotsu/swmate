// ignore_for_file: non_constant_identifier_names

import '../../common/llm_spec/cus_llm_model.dart';

var IG_List = [
  CusSysRoleSpec.tti(
    label: "【英文】未来感摩天大楼",
    systemPrompt: """A futuristic cityscape with towering skyscrapers 
made of glass and metal, glowing with neon lights.""",
  ),
  CusSysRoleSpec.tti(
      label: "【中文】青春少女",
      subtitle: "通义万相，二次元",
      systemPrompt: """度假，草帽，连衣裙，笑容，长发，卷发，浅色头发""",
      negativePrompt: """低分辨率、错误、最差质量、低质量、jpeg 伪影、
丑陋、重复、病态、残缺、超出框架、多余的手指、变异的手、
画得不好的手、画得不好的脸、突变、变形、模糊、脱水、不良的解剖结构、
比例不良、多余肢体、克隆脸、毁容、总体比例、畸形肢体、缺臂、缺腿、
多余手臂、多余腿、融合手指、手指过多、长脖子、用户名、水印、签名
 """),
  CusSysRoleSpec.tti(
    label: "【英文】3D多功能城市",
    subtitle: "通义万相，默认",
    systemPrompt:
        """A 3D render of futuristic city with many green tech lines, futuristic lights, abstract digital world, 
in the style of dark turquoise, light green, dreamlike installations, intricately mapped worlds, constructed photography, datamosh, neo-academism, tinkercore, redshift render, precisionist and complex lines, data visualization""",
    negativePrompt: """低分辨率、错误、最差质量、低质量、jpeg 伪影、
丑陋、重复、病态、残缺、超出框架、多余的手指、变异的手、
画得不好的手、画得不好的脸、突变、变形、模糊、脱水、不良的解剖结构、
比例不良、多余肢体、克隆脸、毁容、总体比例、畸形肢体、缺臂、缺腿、
多余手臂、多余腿、融合手指、手指过多、长脖子、用户名、水印、签名
 """,
  ),
  CusSysRoleSpec.tti(
    label: "【英文】玫瑰花",
    subtitle: "通义万相，默认",
    systemPrompt:
        """an artistic interpretation of Modern Garden Roses using a blend of traditional and modern artistic techniques""",
    negativePrompt: """低分辨率、错误、最差质量、低质量、jpeg 伪影、
丑陋、重复、病态、残缺、超出框架、多余的手指、变异的手、
画得不好的手、画得不好的脸、突变、变形、模糊、脱水、不良的解剖结构、
比例不良、多余肢体、克隆脸、毁容、总体比例、畸形肢体、缺臂、缺腿、
多余手臂、多余腿、融合手指、手指过多、长脖子、用户名、水印、签名
 """,
  ),
  CusSysRoleSpec.tti(
    label: "【中文】月季花和蝴蝶",
    subtitle: "通义万相，默认",
    systemPrompt: """默认，两只彩蝴蝶在长满米白色月季花的草地上嬉戏打闹""",
    negativePrompt: """低分辨率、错误、最差质量、低质量、jpeg 伪影、
丑陋、重复、病态、残缺、超出框架、多余的手指、变异的手、
画得不好的手、画得不好的脸、突变、变形、模糊、脱水、不良的解剖结构、
比例不良、多余肢体、克隆脸、毁容、总体比例、畸形肢体、缺臂、缺腿、
多余手臂、多余腿、融合手指、手指过多、长脖子、用户名、水印、签名
 """,
  ),
  CusSysRoleSpec.tti(
    label: "【英文】圣诞装红衣女孩",
    subtitle: "通义万相，二次元",
    systemPrompt:
        """a very beautiful woman wearing christmas costume in the style of dark academia,,
cute and dreamy,i can&#39;t believe how beautiful this is, shilin huang,kawaii art,
shiny eyes,emotive brushwork, shiny/glossy,full body, hd mod,hikecore,solarizing master,meticulous
""",
    negativePrompt: """低分辨率、错误、最差质量、低质量、jpeg 伪影、
丑陋、重复、病态、残缺、超出框架、多余的手指、变异的手、
画得不好的手、画得不好的脸、突变、变形、模糊、脱水、不良的解剖结构、
比例不良、多余肢体、克隆脸、毁容、总体比例、畸形肢体、缺臂、缺腿、
多余手臂、多余腿、融合手指、手指过多、长脖子、用户名、水印、签名
 """,
  ),
  CusSysRoleSpec.tti(
    label: "【中文】戴着黄色和蓝色项链的动漫女孩",
    subtitle: "通义万相，二次元",
    systemPrompt: """二次元，戴着黄色和蓝色项链的动漫女孩，以弗兰克·索恩的风格绘制，
颜色为深绿松石和浅黑色，风格类似于和田真琴的作品，
浪漫女性化，像美少女战士一样的优雅风格，丰富的面部特写
""",
    negativePrompt: """低分辨率、错误、最差质量、低质量、jpeg 伪影、
丑陋、重复、病态、残缺、超出框架、多余的手指、变异的手、
画得不好的手、画得不好的脸、突变、变形、模糊、脱水、不良的解剖结构、
比例不良、多余肢体、克隆脸、毁容、总体比例、畸形肢体、缺臂、缺腿、
多余手臂、多余腿、融合手指、手指过多、长脖子、用户名、水印、签名
 """,
  ),
  CusSysRoleSpec.tti(
    label: "【英文】全息投影小猫",
    subtitle: "通义万相，默认",
    systemPrompt:
        """a hologram cat, solarizing master, tesseract, made of wire. Y2K aesthetic""",
    negativePrompt: """低分辨率、错误、最差质量、低质量、jpeg 伪影、
丑陋、重复、病态、残缺、超出框架、多余的手指、变异的手、
画得不好的手、画得不好的脸、突变、变形、模糊、脱水、不良的解剖结构、
比例不良、多余肢体、克隆脸、毁容、总体比例、畸形肢体、缺臂、缺腿、
多余手臂、多余腿、融合手指、手指过多、长脖子、用户名、水印、签名
 """,
  ),
  CusSysRoleSpec.tti(
    label: "【中文】二次元可爱美少女战士",
    subtitle: "通义万相，二次元",
    systemPrompt: """二次元，一个超可爱的“美少女战士”（Sailor Moon）与可爱的兔子，
迷你形象，动漫风格的美丽苗条女孩拿着花，深度混合极简主义/极大主义的二维点彩画风，
逼真的油画/水彩画风，可爱幸福的表情，阴影层叠的全息标本，朦胧的红宝石和猫眼石万花筒在缟玛瑙背景中，
弥散的电离层反射，鲜艳的虹彩锐利对比的色彩，借鉴了埃德加·德加、维米尔、穆恰、莫奈等大师的杰作，
复杂的针对氖、金、铀、锡的磁层细节。
高清晰度定义，杰作，超大圆形单色眼睛，全身，大头娃娃，正面视图，可爱的审美，丰富的背景，细节丰富。""",
    negativePrompt: """低分辨率、错误、最差质量、低质量、jpeg 伪影、
丑陋、重复、病态、残缺、超出框架、多余的手指、变异的手、
画得不好的手、画得不好的脸、突变、变形、模糊、脱水、不良的解剖结构、
比例不良、多余肢体、克隆脸、毁容、总体比例、畸形肢体、缺臂、缺腿、
多余手臂、多余腿、融合手指、手指过多、长脖子、用户名、水印、签名
 """,
  ),
  CusSysRoleSpec.tti(
    label: "【中文】红衣女和小黑猫",
    subtitle: "通义万相，二次元",
    systemPrompt:
        """二次元,a woman in a red dress with a white hat and a black cat, 
onmyoji, onmyoji detailed art, kawacy, manhwa, by Yang J, kitsune, 
korean art nouveau anime,reimu hakurei,
kitsune three - tailed fox, anime fantasy illustration, anime illustration""",
    negativePrompt: """低分辨率、错误、最差质量、低质量、jpeg 伪影、
丑陋、重复、病态、残缺、超出框架、多余的手指、变异的手、
画得不好的手、画得不好的脸、突变、变形、模糊、脱水、不良的解剖结构、
比例不良、多余肢体、克隆脸、毁容、总体比例、畸形肢体、缺臂、缺腿、
多余手臂、多余腿、融合手指、手指过多、长脖子、用户名、水印、签名
 """,
  ),
  CusSysRoleSpec.tti(
    label: "【英文】赛博猫咪",
    subtitle: "flux",
    systemPrompt: """In this dazzling neon-lit urban landscape, 
a futuristic cat struts down the bustling city streets with confidence and charisma. 
The cat dons an eye-catching LED mask and a sequined jacket that sparkles with every move, 
reflecting the bright lights and neon signs. The background features towering skyscrapers, 
vibrant colors, and reflections of neon on wet pavement. The overall atmosphere is cinematic, 
capturing the essence of avant-garde fashion in motion, 
as if the scene has been plucked straight from a futuristic, neon-drenched film.""",
  ),
  CusSysRoleSpec.tti(
    label: "【英文】拿战锤骑犀牛的蝙蝠侠",
    subtitle: "flux",
    systemPrompt:
        """In a sprawling, tumultuous battlefield beneath a stormy sky, 
an imposing figure emerges: a colossal, muscular Batman, 
his silhouette dark and striking against the backdrop of chaos. 
His formidable frame is adorned with intricate armor that gleams ominously, 
and an elaborately designed crucifix emblazoned on his chest symbolizes his fierce resolve. 
Clutched tightly in his powerful grip is an oversized sledgehammer, 
its head shimmering with the reflective glint of metallic silver, 
suggesting it has been forged for destruction and righteous retribution.

As he rides atop a powerful, muscular rhinoceros, 
its broad shoulders adorned with battle scars and a menacing stance, 
the ground trembles beneath them. The rhinoceros, snorting and pawing at the earth, 
displays a formidable spirit, exuding an aura of strength that matches its rider. 
The air vibrates with the sounds of clashing metal and distant gunfire, 
while the scent of smoke and gunpowder fills the atmosphere, 
mingling with the earthy smell of churned soil from the fierce combat.

Surrounding them are towering, heavily-armored Warhammer 40k Space Marines, 
their colors vivid in shades of deep red and metallic blue, 
with insignias shining proudly against their intimidating exoskeletons. 
They stand resolute, their bolters raised and ready, 
eyes steely with determination as they prepare for a clash of titanic proportions. 
The camaraderie among the group is palpable, 
with soldiers exchanging brief glances that convey both solidarity and purpose, 
each warrior ready to face the impending chaos alongside the legendary figure in black.

A palpable tension hangs in the air, 
charged with a mix of anticipation and bravery as the heroic ensemble readies 
themselves for battle, united in their sacred mission to confront the forces that 
threaten to engulf their world in darkness. The atmosphere is rife with a sense 
of impending glory, as echoes of battle cries resonate, merging with the rhythmic 
pounding of the rhinoceros’ hooves against the war-torn ground..""",
  ),
  CusSysRoleSpec.tti(
    label: "【英文】沙滩美人",
    subtitle: "flux",
    systemPrompt: """In the vibrant setting of a sunlit beach, 
a stunning beauty stands confidently, showcasing her striking figure. 
Her skin, an immaculate shade of snow-white, 
radiates against the azure backdrop of the clear sky and the sparkling ocean waves 
that gently lap at the shore. She is adorned in a stylish bikini, 
its bright colors popping like tropical flowers against her porcelain complexion, 
accentuating her curves with elegance.

The warmth of the sun casts a golden hue across the scene, 
highlighting the intricate patterns of her bikini and the smooth texture of her skin. 
Her hair, long and flowing, dances playfully in the soft coastal breeze, 
glimmering like spun gold in the sunlight. A hint of playful mischief twinkles in her deep, 
captivating eyes, drawing you into her radiant smile.

In the background, playful waves crash rhythmically against the sandy shore, 
while children laugh and build sandcastles nearby, 
their delighted voices intertwining with the distant melody of a beachside guitar 
strumming calming tunes. The air is filled with the tantalizing scent of saltwater 
mingling with the faint aroma of coconut sunscreen, enhancing the joyful, 
carefree atmosphere of a perfect summer day.""",
  ),
  CusSysRoleSpec.tti(
    label: "【英文】沙滩美人2",
    subtitle: "flux",
    systemPrompt: """In a sun-drenched tropical paradise, a stunningly 
beautiful woman with porcelain skin that glistens in the sunlight stands 
confidently by the shimmering azure waves. Her long, flowing hair cascades 
down her back like a waterfall, glinting with golden highlights that catch 
the light as she moves. She wears a vibrant, patterned bikini that accentuates 
her voluptuous figure, showcasing her ample curves in a way that embodies 
both allure and grace.

As she strolls along the soft, powdery sand, the gentle ocean breeze playfully 
lifts the edges of her bikini, revealing a glimpse of her flawless, sun-kissed skin. 
The warmth of the sun envelops her, cultivating an atmosphere of relaxation and freedom. 
Around her, the rhythmic sound of the crashing waves creates a soothing backdrop, 
while the scent of salty sea air mingles with the faint sweetness of tropical 
flowers in full bloom nearby.

The scene is alive with the sounds of laughter and joyful chatter from a group of 
friends nearby, engaged in a friendly beach volleyball match. She pauses 
for a moment to watch, a playful smile illuminating her face as the sun fills 
the sky with vibrant hues of orange and pink, signaling the approach of sunset. 
The panoramic vista of the beach, dotted with colorful umbrellas and sunbathers, 
enhances the captivating beauty of the moment, capturing the essence of 
a perfect summer day.""",
  ),
];
