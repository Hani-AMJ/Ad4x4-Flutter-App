# OpenStreetMap Available Fields Reference

**Test Waypoint:** Al Ain Zoo  
**Coordinates:** 24.173757, 55.735982  
**Date:** 2025-11-11

---

## 📋 Complete Field Catalog

OpenStreetMap Nominatim Reverse Geocoding API provides **5 main field categories** with **50+ possible fields**. Not all fields are available for every location (desert/remote areas have fewer fields).

---

## 1️⃣ BASIC IDENTIFICATION FIELDS

These fields uniquely identify the location in OpenStreetMap:

| Field | Description | Example (Al Ain Zoo) |
|-------|-------------|----------------------|
| `place_id` | Unique identifier in OSM Nominatim database | 40300131 |
| `osm_type` | Type of OSM object | `way` (can be: node, way, relation) |
| `osm_id` | OpenStreetMap object ID | 101518589 |
| `class` | Main category | `tourism` (amenity, highway, building, etc.) |
| `type` | Specific type within class | `zoo` (hotel, museum, park, etc.) |
| `importance` | Importance score (0.0 to 1.0) | 0.2818 |
| `place_rank` | Ranking in place hierarchy | 30 |
| `addresstype` | Type of address | `tourism` |

---

## 2️⃣ LOCATION FIELDS

Coordinate and boundary information:

| Field | Description | Example (Al Ain Zoo) |
|-------|-------------|----------------------|
| `lat` | Latitude (decimal degrees) | 24.1732514 |
| `lon` | Longitude (decimal degrees) | 55.7355864 |
| `display_name` | Full human-readable address | Al Ain Zoo, Al Ruqiy Street, Falaj Hazza', Al Ain, Abu Dhabi Emirate, UAE |
| `boundingbox` | Area boundaries [S, N, W, E] | [24.1618400, 24.1847240, 55.7224331, 55.7450970] |

**Bounding Box Details:**
- `boundingbox[0]` → South latitude
- `boundingbox[1]` → North latitude
- `boundingbox[2]` → West longitude
- `boundingbox[3]` → East longitude

---

## 3️⃣ ADDRESS COMPONENTS (`address` object)

Hierarchical address breakdown from country to street level:

### **Available Address Fields:**

| Field | Description | Example (Al Ain Zoo) | Typical Availability |
|-------|-------------|----------------------|---------------------|
| `continent` | Continent name | Asia | ⭐⭐⭐⭐⭐ Common |
| `country` | Country name | United Arab Emirates | ⭐⭐⭐⭐⭐ Always |
| `country_code` | ISO country code | `ae` | ⭐⭐⭐⭐⭐ Always |
| `state` | State/Emirate | Abu Dhabi Emirate | ⭐⭐⭐⭐⭐ Common |
| `ISO3166-2-lvl4` | ISO state code | `AE-AZ` | ⭐⭐⭐⭐ Common |
| `county` | County/Municipality | Al Ain | ⭐⭐⭐⭐ Common |
| `city` | City name | Falaj Hazza' | ⭐⭐⭐⭐ Common |
| `town` | Town name (smaller than city) | - | ⭐⭐⭐ Varies |
| `village` | Village name | - | ⭐⭐ Rural areas |
| `suburb` | Suburb/neighborhood | - | ⭐⭐⭐ Urban areas |
| `neighbourhood` | Neighborhood | - | ⭐⭐⭐ Urban areas |
| `quarter` | Quarter/district | - | ⭐⭐ Some cities |
| `hamlet` | Small settlement | - | ⭐⭐ Rural areas |
| `road` | Road/street name | Al Ruqiy Street | ⭐⭐⭐⭐ Urban areas |
| `postcode` | Postal code | - | ⭐⭐ Limited in UAE |
| `house_number` | House/building number | - | ⭐⭐ Urban addresses |
| `tourism` | Tourism facility name | Al Ain Zoo | ⭐⭐⭐ POIs |
| `amenity` | Amenity name | - | ⭐⭐⭐ Facilities |

**For your waypoints (desert/ADNOC stations):**
- ✅ **Always available:** country, country_code, state
- ⚠️ **Sometimes available:** city, county, road
- ❌ **Rarely available:** suburb, neighbourhood, postcode

---

## 4️⃣ NAME DETAILS (`namedetails` object)

Names in multiple languages and variations:

| Field | Description | Example (Al Ain Zoo) | Language |
|-------|-------------|----------------------|----------|
| `name` | Default name (often local language) | حديقة العين للحيوانات | Arabic |
| `name:en` | English name | Al Ain Zoo | English |
| `name:ar` | Arabic name | حديقة العين للحيوانات | Arabic |
| `name:fa` | Persian/Farsi name | باغ‌وحش العین | Persian |
| `name:fr` | French name | - | French |
| `name:de` | German name | - | German |
| `name:es` | Spanish name | - | Spanish |
| `official_name` | Official name | - | Varies |
| `alt_name` | Alternative names | - | Varies |
| `old_name` | Historical names | - | Varies |

**For English output:**
- Use `name:en` for guaranteed English name
- Fallback to `name` if `name:en` not available

---

## 5️⃣ EXTRA TAGS (`extratags` object)

Additional metadata (varies significantly by location type):

### **Common Extra Tags:**

| Field | Description | Example (Al Ain Zoo) | Availability |
|-------|-------------|----------------------|--------------|
| `website` | Official website URL | - | ⭐⭐⭐ POIs/Businesses |
| `phone` | Contact phone number | - | ⭐⭐⭐ Businesses |
| `email` | Contact email | - | ⭐⭐ Businesses |
| `opening_hours` | Opening hours | - | ⭐⭐⭐ Facilities |
| `operator` | Operating entity | - | ⭐⭐⭐ Infrastructure |
| `brand` | Brand name | - | ⭐⭐⭐ Chains (ADNOC) |
| `wikipedia` | Wikipedia article link | ar:حديقة حيوانات العين | ⭐⭐⭐ Notable places |
| `wikipedia:en` | English Wikipedia link | Al Ain Zoo | ⭐⭐⭐ Notable places |
| `wikipedia:ar` | Arabic Wikipedia link | حديقة حيوانات العين | ⭐⭐⭐ Notable places |
| `wikidata` | Wikidata identifier | Q3845012 | ⭐⭐⭐ Notable places |
| `wikimedia_commons` | Wikimedia category | Category:Al Ain Zoo | ⭐⭐ Notable places |
| `description` | Text description | - | ⭐⭐ Some places |
| `capacity` | Capacity information | - | ⭐⭐ Venues |
| `elevation` | Elevation above sea level | - | ⭐⭐ Geographic features |
| `barrier` | Barrier type | fence | ⭐⭐ Infrastructure |
| `start_date` | Establishment date | - | ⭐⭐ Buildings |
| `fuel` | Fuel types (for gas stations) | - | ⭐⭐⭐ ADNOC stations |

**For ADNOC stations specifically:**
- Look for: `brand`, `operator`, `fuel`, `opening_hours`, `phone`

---

## 🎯 RECOMMENDED FIELDS FOR YOUR WAYPOINTS

Based on your waypoint types (ADNOC stations, meeting points, landmarks):

### **Essential Fields (Always Retrieve):**
```
✅ lat, lon              - Coordinates
✅ display_name          - Full address
✅ country               - Country name
✅ state                 - Emirate
✅ county                - Municipality/Region
✅ city/town             - City name
✅ road                  - Road/highway name
✅ name:en               - English name
```

### **High-Value Optional Fields:**
```
⭐ class, type           - Location category
⭐ importance            - Importance score
⭐ suburb/neighbourhood  - Area/district
⭐ ISO3166-2-lvl4       - ISO emirate code
⭐ boundingbox          - Area boundaries
⭐ postcode             - Postal code (if available)
```

### **Metadata Fields (If Available):**
```
💡 wikipedia:en         - Wikipedia article
💡 wikidata            - Wikidata ID
💡 brand               - Brand name (ADNOC)
💡 operator            - Operating entity
💡 fuel                - Fuel types (gas stations)
💡 opening_hours       - Business hours
💡 phone               - Contact number
💡 website             - Official website
```

---

## 📊 ACTUAL DATA SAMPLE: Al Ain Zoo

```json
{
  "place_id": 40300131,
  "osm_type": "way",
  "osm_id": 101518589,
  "lat": "24.1732514",
  "lon": "55.7355864",
  "class": "tourism",
  "type": "zoo",
  "importance": 0.2818,
  "display_name": "Al Ain Zoo, Al Ruqiy Street, Falaj Hazza', Al Ain, Abu Dhabi Emirate, United Arab Emirates",
  
  "address": {
    "tourism": "Al Ain Zoo",
    "road": "Al Ruqiy Street",
    "city": "Falaj Hazza'",
    "county": "Al Ain",
    "state": "Abu Dhabi Emirate",
    "ISO3166-2-lvl4": "AE-AZ",
    "country": "United Arab Emirates",
    "country_code": "ae"
  },
  
  "namedetails": {
    "name": "حديقة العين للحيوانات",
    "name:en": "Al Ain Zoo",
    "name:ar": "حديقة العين للحيوانات",
    "name:fa": "باغ‌وحش العین"
  },
  
  "extratags": {
    "barrier": "fence",
    "wikipedia": "ar:حديقة حيوانات العين",
    "wikipedia:en": "Al Ain Zoo",
    "wikidata": "Q3845012",
    "wikimedia_commons": "Category:Al Ain Zoo"
  },
  
  "boundingbox": ["24.1618400", "24.1847240", "55.7224331", "55.7450970"]
}
```

---

## 🔍 FIELD AVAILABILITY BY LOCATION TYPE

### **Urban Landmarks (like Al Ain Zoo):**
- ✅ **High availability:** 30-40 fields including address, names, metadata
- ✅ **Rich data:** Wikipedia links, multiple languages, opening hours

### **ADNOC Stations (gas stations):**
- ⚠️ **Medium availability:** 15-25 fields
- ✅ **Expected:** Brand, operator, fuel types, road, city
- ❌ **Often missing:** Suburb/neighbourhood, opening hours

### **Desert Meeting Points:**
- ❌ **Low availability:** 10-15 fields
- ✅ **Expected:** Coordinates, country, state
- ❌ **Often missing:** City, road, suburb, all metadata

---

## 💡 RECOMMENDATIONS FOR YOUR USE CASE

### **Standard Enrichment (Current):**
```
- Longitude, Latitude
- City (town/city)
- Area (suburb/neighbourhood)
```

### **Enhanced Enrichment (Suggested):**
```
- Longitude, Latitude
- Display Name (full address)
- Country, State (emirate), County (region)
- City/Town
- Road (highway name)
- Suburb/Neighbourhood (if available)
- ISO3166-2-lvl4 (emirate code)
- Class, Type (location category)
- English Name (name:en)
```

### **Maximum Enrichment (All Useful Fields):**
```
All above PLUS:
- Wikipedia EN link
- Wikidata ID
- Importance score
- Bounding box
- Brand (for ADNOC)
- Fuel types (for gas stations)
```

---

## 🎯 NEXT STEPS: CHOOSE YOUR FIELDS

**Which fields would you like me to retrieve for all 20 waypoints?**

**Option 1: Standard (5 fields)** - Fast, minimal data
- Longitude, Latitude, City, Area, Country

**Option 2: Enhanced (10 fields)** - Balanced, recommended
- Above + Display Name, State, County, Road, ISO Code

**Option 3: Maximum (15+ fields)** - Complete, rich data
- Above + Class, Type, English Name, Wikipedia, Importance, Bounding Box

**Option 4: Custom** - You pick specific fields from the list above

---

**Let me know which fields you want, and I'll re-run the enrichment script to populate all 20 waypoints!** 🚀
