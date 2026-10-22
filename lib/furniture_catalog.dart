import 'room_geometry.dart';

enum FurnitureCategory { seating, sleeping, tables, storage, office, fixtures }

class FurnitureCatalogItem {
  const FurnitureCatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.widthMm,
    required this.depthMm,
    required this.description,
  });

  final String id;
  final String name;
  final FurnitureCategory category;
  final int widthMm;
  final int depthMm;
  final String description;

  MmRect toRect({int x = 0, int y = 0, int rotationTurns = 0}) {
    final rotated = (rotationTurns % 2 == 1);
    final w = rotated ? depthMm : widthMm;
    final h = rotated ? widthMm : depthMm;
    return MmRect(x, y, w, h);
  }
}

/// Catalog of ~40 common standard furniture footprints.
/// Standard measurements in integer millimetres.
class FurnitureCatalog {
  const FurnitureCatalog._();

  static const List<FurnitureCatalogItem> items = [
    // Seating
    FurnitureCatalogItem(
      id: 'armchair',
      name: 'Armchair',
      category: FurnitureCategory.seating,
      widthMm: 900,
      depthMm: 900,
      description: 'Standard single accent armchair',
    ),
    FurnitureCatalogItem(
      id: 'loveseat_2_seater',
      name: 'Loveseat (2-Seater)',
      category: FurnitureCategory.seating,
      widthMm: 1500,
      depthMm: 900,
      description: 'Compact 2-seater sofa',
    ),
    FurnitureCatalogItem(
      id: 'sofa_3_seater',
      name: 'Sofa (3-Seater)',
      category: FurnitureCategory.seating,
      widthMm: 2100,
      depthMm: 950,
      description: 'Standard 3-seater living room couch',
    ),
    FurnitureCatalogItem(
      id: 'sofa_sectional_chaise',
      name: 'Sectional Sofa (with Chaise)',
      category: FurnitureCategory.seating,
      widthMm: 2800,
      depthMm: 1600,
      description: 'L-shaped sectional sofa footprint',
    ),
    FurnitureCatalogItem(
      id: 'ottoman',
      name: 'Ottoman',
      category: FurnitureCategory.seating,
      widthMm: 700,
      depthMm: 600,
      description: 'Upholstered footrest or coffee bench',
    ),
    FurnitureCatalogItem(
      id: 'dining_chair',
      name: 'Dining Chair',
      category: FurnitureCategory.seating,
      widthMm: 480,
      depthMm: 520,
      description: 'Standard dining chair footprint',
    ),
    FurnitureCatalogItem(
      id: 'bar_stool',
      name: 'Bar Stool',
      category: FurnitureCategory.seating,
      widthMm: 420,
      depthMm: 420,
      description: 'Counter or bar height stool',
    ),
    FurnitureCatalogItem(
      id: 'bench',
      name: 'Entry / Dining Bench',
      category: FurnitureCategory.seating,
      widthMm: 1200,
      depthMm: 400,
      description: 'Linear 2-person bench',
    ),

    // Sleeping
    FurnitureCatalogItem(
      id: 'crib',
      name: 'Crib / Toddler Bed',
      category: FurnitureCategory.sleeping,
      widthMm: 750,
      depthMm: 1350,
      description: 'Standard infant or toddler bed',
    ),
    FurnitureCatalogItem(
      id: 'twin_bed',
      name: 'Twin Bed',
      category: FurnitureCategory.sleeping,
      widthMm: 990,
      depthMm: 1910,
      description: 'Standard single / twin mattress and frame',
    ),
    FurnitureCatalogItem(
      id: 'twin_xl_bed',
      name: 'Twin XL Bed',
      category: FurnitureCategory.sleeping,
      widthMm: 990,
      depthMm: 2030,
      description: 'Extended twin dorm/guest bed',
    ),
    FurnitureCatalogItem(
      id: 'full_double_bed',
      name: 'Full / Double Bed',
      category: FurnitureCategory.sleeping,
      widthMm: 1370,
      depthMm: 1910,
      description: 'Standard double bed',
    ),
    FurnitureCatalogItem(
      id: 'queen_bed',
      name: 'Queen Bed',
      category: FurnitureCategory.sleeping,
      widthMm: 1520,
      depthMm: 2030,
      description: 'Standard queen size bed',
    ),
    FurnitureCatalogItem(
      id: 'king_bed',
      name: 'King Bed',
      category: FurnitureCategory.sleeping,
      widthMm: 1930,
      depthMm: 2030,
      description: 'Standard king size bed',
    ),
    FurnitureCatalogItem(
      id: 'california_king_bed',
      name: 'California King Bed',
      category: FurnitureCategory.sleeping,
      widthMm: 1830,
      depthMm: 2130,
      description: 'Longer profile king bed',
    ),
    FurnitureCatalogItem(
      id: 'nightstand_compact',
      name: 'Nightstand (Compact)',
      category: FurnitureCategory.sleeping,
      widthMm: 450,
      depthMm: 400,
      description: 'Bedside table with single drawer',
    ),
    FurnitureCatalogItem(
      id: 'nightstand_standard',
      name: 'Nightstand (Standard)',
      category: FurnitureCategory.sleeping,
      widthMm: 600,
      depthMm: 450,
      description: 'Standard bedroom bedside cabinet',
    ),

    // Tables
    FurnitureCatalogItem(
      id: 'coffee_table_rect',
      name: 'Coffee Table (Rectangular)',
      category: FurnitureCategory.tables,
      widthMm: 1200,
      depthMm: 600,
      description: 'Standard rectangular living room coffee table',
    ),
    FurnitureCatalogItem(
      id: 'coffee_table_round',
      name: 'Coffee Table (Round / Square)',
      category: FurnitureCategory.tables,
      widthMm: 900,
      depthMm: 900,
      description: 'Circular or square center table',
    ),
    FurnitureCatalogItem(
      id: 'side_end_table',
      name: 'Side / End Table',
      category: FurnitureCategory.tables,
      widthMm: 500,
      depthMm: 500,
      description: 'Sofa side accent table',
    ),
    FurnitureCatalogItem(
      id: 'dining_table_4_person',
      name: 'Dining Table (4-Person)',
      category: FurnitureCategory.tables,
      widthMm: 1200,
      depthMm: 800,
      description: 'Compact 4-seat dining table',
    ),
    FurnitureCatalogItem(
      id: 'dining_table_6_person',
      name: 'Dining Table (6-Person)',
      category: FurnitureCategory.tables,
      widthMm: 1800,
      depthMm: 900,
      description: 'Standard 6-seat dining table',
    ),
    FurnitureCatalogItem(
      id: 'dining_table_8_person',
      name: 'Dining Table (8-Person)',
      category: FurnitureCategory.tables,
      widthMm: 2400,
      depthMm: 1000,
      description: 'Large family or banquet dining table',
    ),
    FurnitureCatalogItem(
      id: 'console_table',
      name: 'Console Table',
      category: FurnitureCategory.tables,
      widthMm: 1200,
      depthMm: 350,
      description: 'Slim hallway or behind-couch table',
    ),

    // Storage
    FurnitureCatalogItem(
      id: 'wardrobe_2_door',
      name: 'Wardrobe (2-Door)',
      category: FurnitureCategory.storage,
      widthMm: 1000,
      depthMm: 600,
      description: 'Standard depth 2-door clothes wardrobe',
    ),
    FurnitureCatalogItem(
      id: 'wardrobe_3_door',
      name: 'Wardrobe (3-Door)',
      category: FurnitureCategory.storage,
      widthMm: 1500,
      depthMm: 600,
      description: 'Wide clothes wardrobe with hanging space',
    ),
    FurnitureCatalogItem(
      id: 'dresser_3_drawer',
      name: 'Dresser (3-Drawer / Lowboy)',
      category: FurnitureCategory.storage,
      widthMm: 900,
      depthMm: 480,
      description: 'Compact bedroom chest of drawers',
    ),
    FurnitureCatalogItem(
      id: 'dresser_6_drawer',
      name: 'Dresser (6-Drawer Double)',
      category: FurnitureCategory.storage,
      widthMm: 1400,
      depthMm: 500,
      description: 'Wide double dresser',
    ),
    FurnitureCatalogItem(
      id: 'bookcase_narrow',
      name: 'Bookcase (Narrow)',
      category: FurnitureCategory.storage,
      widthMm: 600,
      depthMm: 300,
      description: 'Slim bookshelf unit',
    ),
    FurnitureCatalogItem(
      id: 'bookcase_wide',
      name: 'Bookcase (Wide)',
      category: FurnitureCategory.storage,
      widthMm: 900,
      depthMm: 320,
      description: 'Standard 5-shelf bookcase',
    ),
    FurnitureCatalogItem(
      id: 'tv_media_console',
      name: 'TV Media Console',
      category: FurnitureCategory.storage,
      widthMm: 1600,
      depthMm: 450,
      description: 'Media console unit for television and consoles',
    ),
    FurnitureCatalogItem(
      id: 'sideboard_buffet',
      name: 'Sideboard / Buffet',
      category: FurnitureCategory.storage,
      widthMm: 1600,
      depthMm: 450,
      description: 'Dining storage credenza',
    ),
    FurnitureCatalogItem(
      id: 'shoe_rack',
      name: 'Shoe Rack / Entry Cabinet',
      category: FurnitureCategory.storage,
      widthMm: 800,
      depthMm: 300,
      description: 'Shallow entryway shoe storage',
    ),

    // Office
    FurnitureCatalogItem(
      id: 'desk_compact',
      name: 'Desk (Compact)',
      category: FurnitureCategory.office,
      widthMm: 1000,
      depthMm: 550,
      description: 'Compact study or laptop desk',
    ),
    FurnitureCatalogItem(
      id: 'desk_standard',
      name: 'Desk (Standard)',
      category: FurnitureCategory.office,
      widthMm: 1400,
      depthMm: 700,
      description: 'Standard office workstation desk',
    ),
    FurnitureCatalogItem(
      id: 'desk_standing_l_shape',
      name: 'Desk (L-Shaped Corner)',
      category: FurnitureCategory.office,
      widthMm: 1600,
      depthMm: 1400,
      description: 'Corner workstation footprint',
    ),
    FurnitureCatalogItem(
      id: 'office_chair',
      name: 'Office Task Chair',
      category: FurnitureCategory.office,
      widthMm: 650,
      depthMm: 650,
      description: 'Ergonomic rolling desk chair footprint',
    ),
    FurnitureCatalogItem(
      id: 'filing_cabinet',
      name: 'Filing Cabinet',
      category: FurnitureCategory.office,
      widthMm: 450,
      depthMm: 600,
      description: '2-drawer office under-desk file pedestal',
    ),

    // Fixtures
    FurnitureCatalogItem(
      id: 'kitchen_island',
      name: 'Kitchen Island (Movable/Fixed)',
      category: FurnitureCategory.fixtures,
      widthMm: 1500,
      depthMm: 900,
      description: 'Prep and dining kitchen island',
    ),
    FurnitureCatalogItem(
      id: 'floor_lamp',
      name: 'Floor Lamp',
      category: FurnitureCategory.fixtures,
      widthMm: 400,
      depthMm: 400,
      description: 'Corner floor reading lamp footprint',
    ),
    FurnitureCatalogItem(
      id: 'coat_rack',
      name: 'Coat Rack Stand',
      category: FurnitureCategory.fixtures,
      widthMm: 450,
      depthMm: 450,
      description: 'Freestanding entry coat tree',
    ),
    FurnitureCatalogItem(
      id: 'large_area_rug',
      name: 'Area Rug (Large 8x10)',
      category: FurnitureCategory.fixtures,
      widthMm: 3000,
      depthMm: 2400,
      description: 'Large floor area rug footprint',
    ),
  ];

  static FurnitureCatalogItem? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
