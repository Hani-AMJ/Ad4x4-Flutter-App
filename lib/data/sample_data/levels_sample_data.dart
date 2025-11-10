import '../models/level_model.dart';

/// Sample levels data - 8 levels (excluding Board member)
/// Based on actual AD4x4 backend data
final List<Level> sampleLevels = [
  Level(
    id: 1,
    name: 'Club Event',
    numericLevel: 1,
    active: true,
    description: 'Social or mixed-skill gatherings—parades, beach/track access, scenic drives. Pace and routes tailored for inclusivity and safety.',
    modifications: 'Stock 4×4 acceptable. Basic safety kit (deflator/gauge, compressor) and radio check; marshals provide recovery oversight.',
  ),
  Level(
    id: 2,
    name: 'ANIT',
    numericLevel: 2,
    active: true,
    description: 'Your very first desert orientation. Learn convoy rules, radio basics, dune approach/exit techniques, and safety. Short, slow, and closely supervised.',
    modifications: 'Stock 4×4 is fine. Basic recovery kit (tire deflator/gauge, shovel), air compressor (recommended). Handheld radio provided/checked at briefing.',
  ),
  Level(
    id: 3,
    name: 'Newbie/ANIT',
    numericLevel: 3,
    active: true,
    description: 'Gentle dunes and easy tracks to build confidence. Practice straight cresting, controlled descents, spacing, and basic recoveries.',
    modifications: 'Stock 4×4 with rated recovery points. Recovery boards, tow rope/kinetic strap (beginner), 2× soft shackles, air compressor.',
  ),
  Level(
    id: 4,
    name: 'Intermediate',
    numericLevel: 4,
    active: true,
    description: 'Medium dunes with steeper climbs/descents and longer side-slopes. Tight convoys, momentum control, and more frequent recoveries.',
    modifications: 'AT tires recommended, front & rear rated recovery points, full recovery kit (kinetic rope, 2–4 soft shackles, bow shackle adapter if needed), shovel, air compressor, handheld/VHF radio.',
  ),
  Level(
    id: 5,
    name: 'Advanced',
    numericLevel: 5,
    active: true,
    description: 'Technical bowls, cross-cresting and soft pockets. Route finding and self-recovery discipline expected. Night sections may appear.',
    modifications: 'AT/MT tires, sand flag, strong recovery kit (kinetic rope, bridle, tree saver), proper radio installation, full-size spare, tools & fluids. Winch recommended.',
  ),
  Level(
    id: 6,
    name: 'Expert',
    numericLevel: 6,
    active: true,
    description: 'Demanding terrain and longer routes with minimal stops. Precise throttle, advanced recoveries, and group support expected.',
    modifications: 'MT tires preferred, suspension in good condition (mild lift acceptable), winch strongly recommended, dual rated recovery points, high-quality kinetic rope, traction boards, first-aid kit, GPS app/waypoints.',
  ),
  Level(
    id: 7,
    name: 'Explorer',
    numericLevel: 7,
    active: true,
    description: 'Expedition-style leadership and navigation. You help plan lines, read dunes, and support marshals on complex sections.',
    modifications: 'Winch mandatory or equivalent recovery capability, full professional recovery kit (kinetic & static straps, bridles, multiple soft shackles), traction boards, fire extinguisher, tools/spares, onboard or hard-mounted radio, navigation kit.',
  ),
  Level(
    id: 8,
    name: 'Marshal',
    numericLevel: 8,
    active: true,
    description: 'Trip leadership, safety control, and training. You manage check-in/out, incidents, multiple recoveries, and team pacing.',
    modifications: 'Winch mandatory, comprehensive recovery gear (multiple kinetic ropes, bridles, pulleys, tree saver, boards), spare radios, medical kit, sand flag, lighting, navigation & comms backups.',
  ),
];
