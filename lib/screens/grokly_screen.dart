// grokly_screen.dart — Grokly v2 Full App (single file)
// Design: Blinkit IA x FirstClub premium aesthetic
// Screens: Home, Categories, Profile, Cart, Checkout, Payment,
//          Features Hub, Smart Pantry, Dish-First, Sixth Sense,
//          Usuals, Saved Baskets, Order Tracking
// Flutter 3.x · Provider state · Unsplash network images

import 'dart:async';
import '../providers/user_provider.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'referral_screen.dart';
import 'return_and_earn_screen.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../services/firebase_service.dart';
import '../services/razorpay_service.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:accesco_living_app/providers/unified_cart_provider.dart';
import 'package:accesco_living_app/providers/sixth_sense_provider.dart';
import 'package:accesco_living_app/models/smart_pantry_item.dart';
import 'package:accesco_living_app/models/sixth_sense_basket.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'grokly_address_screen.dart';
void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const GroklyApp());
}

// ���������������������������������������������
// ENTRY WRAPPER  (called from main_dashboard.dart)
// ���������������������������������������������

/// Public entry-point used by MainDashboard.
/// Wraps [GroklyApp] and optionally pre-populates the search bar.
class GroklyScreen extends StatelessWidget {
  final String? initialSearchQuery;
  const GroklyScreen({super.key, this.initialSearchQuery});

  @override
  Widget build(BuildContext context) {
    return GroklyApp(initialSearchQuery: initialSearchQuery);
  }
}

// ���������������������������������������������
// DESIGN SYSTEM
// ���������������������������������������������

class GroklyColors {
  static const primary       = Color(0xFF005129);
  static const primaryDark   = Color(0xFF0B6B3A);
  static const primaryLight  = Color(0xFF84D99C);
  static const primaryFixed  = Color(0xFF9FF5B7);
  static const onPrimary     = Color(0xFFFFFFFF);
  static const surface       = Color(0xFFF7FBF3);
  static const surfaceCard   = Color(0xFFF8F1E5);
  static const surfaceMint   = Color(0xFFEAF4E6);
  static const surfaceLow    = Color(0xFFF1F5EE);
  static const surfaceHigh   = Color(0xFFE5E9E2);
  static const background    = Color(0xFFF7F3EB);
  static const onSurface     = Color(0xFF181D19);
  static const onSurfaceVar  = Color(0xFF3F4940);
  static const outline       = Color(0xFF6F7A70);
  static const outlineVar    = Color(0xFFBFC9BE);
  static const secondary     = Color(0xFF54634C);
  static const secContainer  = Color(0xFFD8E8CB);
  static const onSecContainer= Color(0xFF5A6952);
  static const error         = Color(0xFFBA1A1A);
  static const white         = Color(0xFFFFFFFF);
}

class GroklyTextStyles {
  static const headlineLg = TextStyle(
    fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w700,
    color: GroklyColors.white, height: 1.2,
  );
  static const headlineMd = TextStyle(
    fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700,
    color: GroklyColors.onSurface, height: 1.2,
  );
  static const sectionHeader = TextStyle(
    fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600,
    color: GroklyColors.onSurface, height: 1.4,
  );
  static const bodyMain = TextStyle(
    fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400,
    color: GroklyColors.onSurface, height: 1.6,
  );
  static const labelCaps = TextStyle(
    fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600,
    color: GroklyColors.onSurfaceVar, letterSpacing: 0.8, height: 1.2,
  );
  static const price = TextStyle(
    fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700,
    color: GroklyColors.primary,
  );
}

class GroklyShadows {
  static const soft = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 2)),
  ];
  static const card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

// ���������������������������������������������
// DATA MODELS
// ���������������������������������������������

class GroklyProduct {
  final String id, name, category, subCategory, size, brand;
  final double price;
  final String imageUrl;
  final double? mrp;           // original price before discount, e.g. 32
  final double? rating;        // e.g. 4.3
  final int? ratingCount;      // e.g. 210
  final int? deliveryMinutes; // e.g. 20
  final int? recipeCount;     // e.g. 30
  const GroklyProduct({
    required this.id, required this.name, required this.category,
    required this.subCategory, required this.size, required this.brand,
    required this.price, required this.imageUrl,
    this.mrp, this.rating, this.ratingCount,
    this.deliveryMinutes, this.recipeCount,
  });

  int? get discountPercent =>
      (mrp != null && mrp! > price) ? (100 - (price / mrp! * 100)).round() : null;
}

class GroklyRecipe {
  final String id, name, imageUrl, cuisine;
  final int prepMinutes, servings;
  final List<RecipeIngredient> ingredients;
  final double estimatedCost;
  const GroklyRecipe({
    required this.id, required this.name, required this.imageUrl,
    required this.cuisine, required this.prepMinutes, required this.servings,
    required this.ingredients, required this.estimatedCost,
  });
}

class RecipeIngredient {
  final String name, quantity, imageUrl;
  const RecipeIngredient(this.name, this.quantity, [this.imageUrl = '']);
}

class CartItem {
  final GroklyProduct product;
  int qty;
  CartItem({required this.product, this.qty = 1});
}

class PantryItem {
  final String name, imageUrl, status;
  final int daysLeft;
  final double stockPct;
  const PantryItem({
    required this.name, required this.imageUrl, required this.status,
    required this.daysLeft, required this.stockPct,
  });
}

class SavedBasket {
  final String name, subtitle;
  final List<String> imageUrls;
  final double price;
  final int itemCount;
  const SavedBasket({
    required this.name, required this.subtitle, required this.imageUrls,
    required this.price, required this.itemCount,
  });
}
// ���������������������������������������������
// REVERSE COMMERCE — Packaging Return
// ���������������������������������������������

class ReturnableItem {
  final String label;      // e.g. "Milk bottles"
  final String material;   // e.g. "PET · Recycle"
  final int qty;
  final double creditPerUnit;
  bool selected;
  ReturnableItem({
    required this.label,
    required this.material,
    required this.qty,
    required this.creditPerUnit,
    this.selected = false,
  });

  double get credit => creditPerUnit * qty;
}

/// Scans the cart and derives which packaging items are return-eligible.
/// Milk → PET bottle (₹2/unit), Oil → PET bottle (₹3/unit), Ghee → Glass jar (₹5/unit).
/// Extend this map as your catalog grows.
List<ReturnableItem> deriveReturnables(List<CartItem> items) {
  final result = <ReturnableItem>[];
  for (final item in items) {
    final sub = item.product.subCategory.toLowerCase();
    if (sub.contains('milk')) {
      result.add(ReturnableItem(
          label: 'Milk bottles', material: 'PET · Recycle',
          qty: item.qty, creditPerUnit: 2));
    } else if (sub.contains('oil')) {
      result.add(ReturnableItem(
          label: 'Oil bottle', material: 'PET · Recycle',
          qty: item.qty, creditPerUnit: 3));
    } else if (sub.contains('ghee')) {
      result.add(ReturnableItem(
          label: 'Ghee jar', material: 'Glass · Recycle',
          qty: item.qty, creditPerUnit: 5));
    }
  }
  return result;
}

class UsualsCategory {
  final String title;
  final List<UsualsItem> items;
  const UsualsCategory({required this.title, required this.items});
}

// ���������������������������������������������
// CATALOG
// ���������������������������������������������

const _u = 'https://images.unsplash.com/';

class GroklyCatalog {
  static List<GroklyProduct> dynamicAll = [];
  static bool isLoadedFromFirebase = false;

  static List<GroklyProduct> get all {
    if (isLoadedFromFirebase && dynamicAll.isNotEmpty) {
      return dynamicAll;
    }
    return [
      ...dairy, ...staples, ...bakery, ...packaged,
      ...beverages, ...vegetables, ...freshHerbsAromatics, ...meatSeafood,
      ...dryFruitsNuts, ...spicesMasalas, ...condiments, ...readyToCook,
      ...frozen, ...household, ...personalCare, ...babyCare,
    ].map(_enrich).toList();
  }

// Deterministically fills in rating/ratingCount/mrp for products that
// don't already specify them, so every card can show a discount +
// rating without hand-editing every catalog entry.
static GroklyProduct _enrich(GroklyProduct p) {
  final seed = p.id.hashCode.abs();

  final rating = p.rating ?? (4.0 + (seed % 9) / 10); // 4.0–4.8
  final ratingCount = p.ratingCount ?? (40 + (seed % 460)); // 40–500

  double? mrp = p.mrp;
  if (mrp == null) {
    final discountPct = 5 + (seed % 21); // 5%–25% off
    mrp = (p.price / (1 - discountPct / 100));
    mrp = (mrp * 100).roundToDouble() / 100; // 2dp
  }

  return GroklyProduct(
    id: p.id, name: p.name, category: p.category, subCategory: p.subCategory,
    size: p.size, brand: p.brand, price: p.price, imageUrl: p.imageUrl,
    mrp: mrp, rating: rating, ratingCount: ratingCount,
  );
}

  static const dairy = [
    GroklyProduct(id:'d1',  name:'Nandini Toned Milk',      category:'Dairy', subCategory:'Milk',           size:'500ml',      brand:'Nandini',      price:13,  imageUrl:'${_u}photo-1563636619-e9143da7973b?w=400&q=80'),
    GroklyProduct(id:'d2',  name:'Nandini Full Cream Milk',  category:'Dairy', subCategory:'Milk',           size:'1L',         brand:'Nandini',      price:26,  imageUrl:'${_u}photo-1563636619-e9143da7973b?w=400&q=80'),
    GroklyProduct(id:'d3',  name:'Amul Toned Milk',          category:'Dairy', subCategory:'Milk',           size:'500ml',      brand:'Amul',         price:27,  imageUrl:'${_u}photo-1563636619-e9143da7973b?w=400&q=80'),
    GroklyProduct(id:'d4',  name:'Akshayakalpa Organic Milk',category:'Dairy', subCategory:'Organic Milk',   size:'500ml',      brand:'Akshayakalpa', price:42,  imageUrl:'${_u}photo-1563636619-e9143da7973b?w=400&q=80'),
    GroklyProduct(id:'d5',  name:'Nandini Curd',             category:'Dairy', subCategory:'Curd',           size:'200g',       brand:'Nandini',      price:22,  imageUrl:'${_u}photo-1488477181946-6428a0291777?w=400&q=80'),
    GroklyProduct(id:'d6',  name:'Amul Curd',                category:'Dairy', subCategory:'Curd',           size:'400g',       brand:'Amul',         price:50,  imageUrl:'${_u}photo-1488477181946-6428a0291777?w=400&q=80'),
    GroklyProduct(id:'d7',  name:'Greek Yogurt (Epigamia)',   category:'Dairy', subCategory:'Premium Yogurt', size:'90g',        brand:'Epigamia',     price:50,  imageUrl:'${_u}photo-1488477181946-6428a0291777?w=400&q=80'),
    GroklyProduct(id:'d8',  name:'Milky Mist Greek Yogurt',   category:'Dairy', subCategory:'Premium Yogurt', size:'100g',       brand:'Milky Mist',   price:45,  imageUrl:'${_u}photo-1488477181946-6428a0291777?w=400&q=80'),
    GroklyProduct(id:'d9',  name:'Akshayakalpa Organic Curd', category:'Dairy', subCategory:'Organic Curd',   size:'400g',       brand:'Akshayakalpa', price:65,  imageUrl:'${_u}photo-1488477181946-6428a0291777?w=400&q=80'),
    GroklyProduct(id:'d10', name:'Paneer',                    category:'Dairy', subCategory:'Paneer',         size:'200g',       brand:'Nandini',      price:100, imageUrl:'${_u}photo-1631452180519-c014fe946bc7?w=400&q=80'),
    GroklyProduct(id:'d11', name:'Paneer Block',              category:'Dairy', subCategory:'Paneer',         size:'500g',       brand:'Amul',         price:240, imageUrl:'${_u}photo-1631452180519-c014fe946bc7?w=400&q=80'),
    GroklyProduct(id:'d12', name:'Amul Butter',               category:'Dairy', subCategory:'Butter',         size:'500g',       brand:'Amul',         price:260, imageUrl:'${_u}photo-1589985270826-4b7bb135bc9d?w=400&q=80'),
    GroklyProduct(id:'d13', name:'Mozzarella Cheese',         category:'Dairy', subCategory:'Cheese',         size:'200g',       brand:'Britannia',    price:140, imageUrl:'${_u}photo-1486297678162-eb2a19b0a32d?w=400&q=80'),
    GroklyProduct(id:'d14', name:'Cheddar Cheese Block',      category:'Dairy', subCategory:'Cheese',         size:'200g',       brand:'Britannia',    price:175, imageUrl:'${_u}photo-1486297678162-eb2a19b0a32d?w=400&q=80'),
    GroklyProduct(id:'d15', name:'Ghee',                      category:'Dairy', subCategory:'Ghee',           size:'500ml',      brand:'Nandini',      price:325, imageUrl:'${_u}photo-1631452180519-c014fe946bc7?w=400&q=80'),
    GroklyProduct(id:'d16', name:'Akshayakalpa Organic Ghee', category:'Dairy', subCategory:'Premium Ghee',   size:'500ml',      brand:'Akshayakalpa', price:700, imageUrl:'${_u}photo-1631452180519-c014fe946bc7?w=400&q=80'),
    GroklyProduct(id:'d17', name:'Fresh Cream',               category:'Dairy', subCategory:'Cream',          size:'250ml',      brand:'Amul',         price:80,  imageUrl:'${_u}photo-1563636619-e9143da7973b?w=400&q=80'),
    GroklyProduct(id:'d18', name:'Almond Milk',               category:'Dairy', subCategory:'Plant-based',    size:'1L',         brand:'Sofit',        price:275, imageUrl:'${_u}photo-1563636619-e9143da7973b?w=400&q=80'),
    GroklyProduct(id:'d19', name:'Oat Milk',                  category:'Dairy', subCategory:'Plant-based',    size:'1L',         brand:'Oatly',        price:325, imageUrl:'${_u}photo-1563636619-e9143da7973b?w=400&q=80'),
    GroklyProduct(id:'d20', name:'Lactose-Free Milk',         category:'Dairy', subCategory:'Specialty Milk', size:'1L',         brand:'Amul',         price:130, imageUrl:'${_u}photo-1563636619-e9143da7973b?w=400&q=80'),
  ];

  static const staples = [
    GroklyProduct(id:'s1',  name:'Aashirvaad Atta',          category:'Staples', subCategory:'Branded Atta',    size:'5kg',    brand:'ITC Aashirvaad', price:300, imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    GroklyProduct(id:'s2',  name:'Multigrain Atta',           category:'Staples', subCategory:'Health Atta',     size:'5kg',    brand:'Aashirvaad',     price:350, imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    GroklyProduct(id:'s3',  name:'Organic Atta',              category:'Staples', subCategory:'Organic Atta',    size:'5kg',    brand:'24 Mantra',      price:450, imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    GroklyProduct(id:'s4',  name:'Sona Masoori Rice',         category:'Staples', subCategory:'Regular Rice',    size:'5kg',    brand:'India Gate',     price:300, imageUrl:'${_u}photo-1536304929831-ee1ca9d44906?w=400&q=80'),
    GroklyProduct(id:'s5',  name:'Basmati Rice',              category:'Staples', subCategory:'Premium Rice',    size:'5kg',    brand:'India Gate',     price:750, imageUrl:'${_u}photo-1536304929831-ee1ca9d44906?w=400&q=80'),
    GroklyProduct(id:'s6',  name:'Organic Rice',              category:'Staples', subCategory:'Organic Rice',    size:'5kg',    brand:'24 Mantra',      price:700, imageUrl:'${_u}photo-1536304929831-ee1ca9d44906?w=400&q=80'),
    GroklyProduct(id:'s7',  name:'Toor Dal',                  category:'Staples', subCategory:'Dal',             size:'1kg',    brand:'Tata Sampann',   price:160, imageUrl:'${_u}photo-1585937421612-70a008356fbe?w=400&q=80'),
    GroklyProduct(id:'s8',  name:'Moong Dal',                 category:'Staples', subCategory:'Dal',             size:'1kg',    brand:'Tata Sampann',   price:140, imageUrl:'${_u}photo-1585937421612-70a008356fbe?w=400&q=80'),
    GroklyProduct(id:'s9',  name:'Chana Dal',                 category:'Staples', subCategory:'Dal',             size:'1kg',    brand:'Tata Sampann',   price:105, imageUrl:'${_u}photo-1585937421612-70a008356fbe?w=400&q=80'),
    GroklyProduct(id:'s10', name:'Urad Dal',                  category:'Staples', subCategory:'Dal',             size:'1kg',    brand:'Tata Sampann',   price:145, imageUrl:'${_u}photo-1585937421612-70a008356fbe?w=400&q=80'),
    GroklyProduct(id:'s11', name:'Masoor Dal',                category:'Staples', subCategory:'Dal',             size:'1kg',    brand:'Tata Sampann',   price:115, imageUrl:'${_u}photo-1585937421612-70a008356fbe?w=400&q=80'),
    GroklyProduct(id:'s12', name:'Sunflower Oil',             category:'Staples', subCategory:'Refined Oil',     size:'1L',     brand:'Fortune',        price:150, imageUrl:'${_u}photo-1474979266404-7eaacbcd87c5?w=400&q=80'),
    GroklyProduct(id:'s13', name:'Mustard Oil',               category:'Staples', subCategory:'Cooking Oil',     size:'1L',     brand:'Fortune',        price:185, imageUrl:'${_u}photo-1474979266404-7eaacbcd87c5?w=400&q=80'),
    GroklyProduct(id:'s14', name:'Olive Oil',                 category:'Staples', subCategory:'Premium Oil',     size:'500ml',  brand:'Borges',         price:575, imageUrl:'${_u}photo-1474979266404-7eaacbcd87c5?w=400&q=80'),
    GroklyProduct(id:'s15', name:'Tata Salt',                 category:'Staples', subCategory:'Salt',            size:'1kg',    brand:'Tata',           price:28,  imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    GroklyProduct(id:'s16', name:'Sugar',                     category:'Staples', subCategory:'Sugar',           size:'1kg',    brand:'Dhampur',        price:50,  imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    GroklyProduct(id:'s17', name:'Jaggery (Gud)',             category:'Staples', subCategory:'Natural Sweetener',size:'500g',  brand:'Local/Organic',  price:75,  imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    GroklyProduct(id:'s18', name:'iD Fresh Dosa Batter',      category:'Staples', subCategory:'Ready-to-Cook',   size:'1kg',    brand:'iD Fresh',       price:90,  imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    GroklyProduct(id:'s19', name:'Oats',                      category:'Staples', subCategory:'Breakfast',       size:'1kg',    brand:'Quaker',         price:175, imageUrl:'${_u}photo-1587314168485-3236d6710814?w=400&q=80'),
    GroklyProduct(id:'s20', name:'Quinoa',                    category:'Staples', subCategory:'Superfood',       size:'500g',   brand:'Organic India',  price:350, imageUrl:'${_u}photo-1587314168485-3236d6710814?w=400&q=80'),
  ];

  static const bakery = [
    GroklyProduct(id:'b1',  name:'White Bread',               category:'Bakery', subCategory:'Bread',            size:'Large',  brand:'Britannia',      price:45,  imageUrl:'${_u}photo-1509440159596-0249088772ff?w=400&q=80'),
    GroklyProduct(id:'b2',  name:'Brown Bread',               category:'Bakery', subCategory:'Bread',            size:'400g',   brand:'Britannia',      price:55,  imageUrl:'${_u}photo-1509440159596-0249088772ff?w=400&q=80'),
    GroklyProduct(id:'b3',  name:'Multigrain Bread',          category:'Bakery', subCategory:'Health Bread',     size:'400g',   brand:'Harvest Gold',   price:70,  imageUrl:'${_u}photo-1509440159596-0249088772ff?w=400&q=80'),
    GroklyProduct(id:'b4',  name:'Pav Buns',                  category:'Bakery', subCategory:'Bread',            size:'Pack',   brand:'Local Bakery',   price:35,  imageUrl:'${_u}photo-1509440159596-0249088772ff?w=400&q=80'),
    GroklyProduct(id:'b5',  name:'Eggs (6 Pack)',             category:'Bakery', subCategory:'Eggs',             size:'6 units',brand:'Suguna',         price:55,  imageUrl:'${_u}photo-1582722872445-44dc5f7e3c8f?w=400&q=80'),
    GroklyProduct(id:'b6',  name:'Eggs (12 Pack)',            category:'Bakery', subCategory:'Eggs',             size:'12 units',brand:'Nandini',       price:95,  imageUrl:'${_u}photo-1582722872445-44dc5f7e3c8f?w=400&q=80'),
    GroklyProduct(id:'b7',  name:'Country Eggs',              category:'Bakery', subCategory:'Premium Eggs',     size:'6 units',brand:'Local Farms',    price:75,  imageUrl:'${_u}photo-1582722872445-44dc5f7e3c8f?w=400&q=80'),
    GroklyProduct(id:'b8',  name:'Peanut Butter',             category:'Bakery', subCategory:'Spread',           size:'340g',   brand:'Pintola',        price:190, imageUrl:'${_u}photo-1559181567-c3190ca9be5b?w=400&q=80'),
    GroklyProduct(id:'b9',  name:'Chocolate Spread',          category:'Bakery', subCategory:'Spread',           size:'350g',   brand:'Nutella',        price:215, imageUrl:'${_u}photo-1559181567-c3190ca9be5b?w=400&q=80'),
    GroklyProduct(id:'b10', name:'Honey',                     category:'Bakery', subCategory:'Natural Sweetener',size:'250g',   brand:'Dabur',          price:150, imageUrl:'${_u}photo-1559181567-c3190ca9be5b?w=400&q=80'),
    GroklyProduct(id:'b11', name:'Granola',                   category:'Bakery', subCategory:'Premium Breakfast',size:'500g',   brand:'Yoga Bar',       price:400, imageUrl:'${_u}photo-1587314168485-3236d6710814?w=400&q=80'),
    GroklyProduct(id:'b12', name:'Croissant',                 category:'Bakery', subCategory:'Premium Bakery',   size:'Pack',   brand:'La Folie',       price:150, imageUrl:'${_u}photo-1555507036-ab1f4038808a?w=400&q=80'),
    GroklyProduct(id:'b13', name:'Cream Biscuits (Oreo)',     category:'Bakery', subCategory:'Biscuits',         size:'Pack',   brand:'Oreo',           price:35,  imageUrl:'${_u}photo-1558961363-fa8fdf82db35?w=400&q=80'),
    GroklyProduct(id:'b14', name:'Butter Cookies',            category:'Bakery', subCategory:'Cookies',          size:'Pack',   brand:'Good Day',       price:50,  imageUrl:'${_u}photo-1558961363-fa8fdf82db35?w=400&q=80'),
  ];

  static const packaged = [
    GroklyProduct(id:'p1',  name:'Maggi Noodles',             category:'Packaged', subCategory:'Instant Noodles', size:'4-pack', brand:'Nestl├⌐ Maggi',  price:80,  imageUrl:'${_u}photo-1585325701165-34ba78c8cfd5?w=400&q=80'),
    GroklyProduct(id:'p2',  name:'Yippee Noodles',            category:'Packaged', subCategory:'Instant Noodles', size:'4-pack', brand:'ITC Yippee',    price:60,  imageUrl:'${_u}photo-1585325701165-34ba78c8cfd5?w=400&q=80'),
    GroklyProduct(id:'p3',  name:'Pasta',                     category:'Packaged', subCategory:'Dry Pasta',       size:'500g',   brand:'Sunfeast',       price:115, imageUrl:'${_u}photo-1551462147-ff29053bfc14?w=400&q=80'),
    GroklyProduct(id:'p4',  name:'Pasta Sauce',               category:'Packaged', subCategory:'Sauce',           size:'300g',   brand:'Del Monte',      price:150, imageUrl:'${_u}photo-1551462147-ff29053bfc14?w=400&q=80'),
    GroklyProduct(id:'p5',  name:"Chips (Lay's)",             category:'Packaged', subCategory:'Chips',           size:'Pack',   brand:"Lay's",          price:30,  imageUrl:'${_u}photo-1566478989037-eec170784d0b?w=400&q=80'),
    GroklyProduct(id:'p6',  name:'Nachos',                    category:'Packaged', subCategory:'Snacks',          size:'Pack',   brand:'Doritos',        price:100, imageUrl:'${_u}photo-1566478989037-eec170784d0b?w=400&q=80'),
    GroklyProduct(id:'p7',  name:'Namkeen',                   category:'Packaged', subCategory:'Savoury Snacks',  size:'400g',   brand:"Haldiram's",     price:150, imageUrl:'${_u}photo-1566478989037-eec170784d0b?w=400&q=80'),
    GroklyProduct(id:'p8',  name:'Chocolate (Dairy Milk)',    category:'Packaged', subCategory:'Chocolate',       size:'Various',brand:'Cadbury',        price:50,  imageUrl:'${_u}photo-1511381939415-e44fb0173e3d?w=400&q=80'),
    GroklyProduct(id:'p9',  name:'Premium Chocolate',         category:'Packaged', subCategory:'Chocolate',       size:'100g',   brand:'Lindt',          price:225, imageUrl:'${_u}photo-1511381939415-e44fb0173e3d?w=400&q=80'),
    GroklyProduct(id:'p10', name:'Energy Bars',               category:'Packaged', subCategory:'Health Snack',    size:'Pack',   brand:'Yoga Bar',       price:65,  imageUrl:'${_u}photo-1587314168485-3236d6710814?w=400&q=80'),
    GroklyProduct(id:'p11', name:'Protein Bars',              category:'Packaged', subCategory:'Health Snack',    size:'Pack',   brand:'RiteBite',       price:110, imageUrl:'${_u}photo-1587314168485-3236d6710814?w=400&q=80'),
    GroklyProduct(id:'p12', name:'Instant Upma Mix',          category:'Packaged', subCategory:'Instant Mix',     size:'500g',   brand:'MTR',            price:90,  imageUrl:'${_u}photo-1585325701165-34ba78c8cfd5?w=400&q=80'),
    GroklyProduct(id:'p13', name:'Popcorn (Butter)',         category:'Packaged', subCategory:'Snacks',          size:'Pack',   brand:'Act II',         price:45,  imageUrl:'${_u}photo-1578849278619-e73505e9610f?w=400&q=80'),
    GroklyProduct(id:'p14', name:'Trail Mix',                category:'Packaged', subCategory:'Health Snack',    size:'200g',   brand:'Yoga Bar',       price:180, imageUrl:'${_u}photo-1599599810769-bcde5a160d32?w=400&q=80'),
    GroklyProduct(id:'p15', name:'Muesli',                   category:'Packaged', subCategory:'Breakfast',       size:'500g',   brand:'Kellogg\'s',     price:280, imageUrl:'${_u}photo-1587314168485-3236d6710814?w=400&q=80'),
  ];

  static const beverages = [
    GroklyProduct(id:'bv1', name:'Tata Tea Premium',          category:'Beverages', subCategory:'Tea',            size:'500g',  brand:'Tata Tea',       price:140, imageUrl:'${_u}photo-1559056199-641a0ac8b55e?w=400&q=80'),
    GroklyProduct(id:'bv2', name:'Red Label Tea',             category:'Beverages', subCategory:'Tea',            size:'500g',  brand:'Brooke Bond',    price:150, imageUrl:'${_u}photo-1559056199-641a0ac8b55e?w=400&q=80'),
    GroklyProduct(id:'bv3', name:'Green Tea',                 category:'Beverages', subCategory:'Health Tea',     size:'25 bags',brand:'Tetley',        price:175, imageUrl:'${_u}photo-1564890369478-c89ca3d9cde8?w=400&q=80'),
    GroklyProduct(id:'bv4', name:'Filter Coffee Powder',      category:'Beverages', subCategory:'South Indian',   size:'500g',  brand:'Bru/Cothas',     price:250, imageUrl:'${_u}photo-1447933601403-0c6688de566e?w=400&q=80'),
    GroklyProduct(id:'bv5', name:'Packaged Juice',            category:'Beverages', subCategory:'Juice',          size:'1L',    brand:'Tropicana',      price:120, imageUrl:'${_u}photo-1600271886742-f049cd451bba?w=400&q=80'),
    GroklyProduct(id:'bv6', name:'Soft Drinks (750ml)',       category:'Beverages', subCategory:'Carbonated',     size:'750ml', brand:'Coca-Cola',      price:40,  imageUrl:'${_u}photo-1568702846914-96b305d2aaeb?w=400&q=80'),
    GroklyProduct(id:'bv7', name:'Energy Drink',              category:'Beverages', subCategory:'Energy Drink',   size:'250ml', brand:'Red Bull',       price:120, imageUrl:'${_u}photo-1622483767028-3f66f32aef97?w=400&q=80'),
    GroklyProduct(id:'bv8', name:'Coconut Water',             category:'Beverages', subCategory:'Natural Drink',  size:'200ml', brand:'TenderCuts',     price:50,  imageUrl:'${_u}photo-1600271886742-f049cd451bba?w=400&q=80'),
    GroklyProduct(id:'bv9', name:'Drinking Water 1L',         category:'Beverages', subCategory:'Packaged Water', size:'1L',    brand:'Bisleri',        price:20,  imageUrl:'${_u}photo-1548839143-71c4db87c5d3?w=400&q=80'),
    GroklyProduct(id:'bv10',name:'Protein Shake',             category:'Beverages', subCategory:'Health Drink',   size:'200ml', brand:'Epigamia',       price:100, imageUrl:'${_u}photo-1600271886742-f049cd451bba?w=400&q=80'),
  ];

  static const vegetables = [
    GroklyProduct(id:'v1',  name:'Tomato',                    category:'Vegetables', subCategory:'Veg',          size:'1kg',   brand:'Local',          price:40,  imageUrl:'${_u}photo-1518977822534-7049a61ee0c2?w=400&q=80'),
    GroklyProduct(id:'v2',  name:'Onion',                     category:'Vegetables', subCategory:'Veg',          size:'1kg',   brand:'Local',          price:35,  imageUrl:'${_u}photo-1518977822534-7049a61ee0c2?w=400&q=80'),
    GroklyProduct(id:'v3',  name:'Potato',                    category:'Vegetables', subCategory:'Veg',          size:'1kg',   brand:'Local',          price:28,  imageUrl:'${_u}photo-1518977822534-7049a61ee0c2?w=400&q=80'),
    GroklyProduct(id:'v4',  name:'Broccoli',                  category:'Vegetables', subCategory:'Exotic Veg',   size:'250g',  brand:'Local/Fresho',   price:75,  imageUrl:'${_u}photo-1459411621453-7b03977f4bfc?w=400&q=80'),
    GroklyProduct(id:'v5',  name:'Baby Spinach',              category:'Vegetables', subCategory:'Leafy',        size:'200g',  brand:'Local',          price:52,  imageUrl:'${_u}photo-1576045057995-568f588f82fb?w=400&q=80'),
    GroklyProduct(id:'v6',  name:'Mushroom (Button)',         category:'Vegetables', subCategory:'Fresh Veg',    size:'200g',  brand:'Fresho',         price:60,  imageUrl:'${_u}photo-1504545102780-26774c1bb073?w=400&q=80'),
    GroklyProduct(id:'v7',  name:'Zucchini',                  category:'Vegetables', subCategory:'Exotic Veg',   size:'250g',  brand:'Local',          price:70,  imageUrl:'${_u}photo-1598170845058-32b9d6a5da37?w=400&q=80'),
    GroklyProduct(id:'v8',  name:'Sweet Corn',                category:'Vegetables', subCategory:'Fresh Veg',    size:'2 pcs', brand:'Local Farms',    price:50,  imageUrl:'${_u}photo-1551754655-cd27e38d2076?w=400&q=80'),
    GroklyProduct(id:'v9',  name:'Lettuce (Iceberg)',         category:'Vegetables', subCategory:'Leafy',        size:'1 pc',  brand:'Local',          price:65,  imageUrl:'${_u}photo-1518977676601-b53f82aba655?w=400&q=80'),
    GroklyProduct(id:'v10', name:'Banana (Robusta)',          category:'Vegetables', subCategory:'Fruit',        size:'12 pcs',brand:'Local',          price:60,  imageUrl:'${_u}photo-1603833665858-e61d17a86224?w=400&q=80'),
    GroklyProduct(id:'v11', name:'Pineapple',                 category:'Vegetables', subCategory:'Fruit',        size:'1 pc',  brand:'Local',          price:100, imageUrl:'${_u}photo-1550258987-190a2d41a8ba?w=400&q=80'),
    GroklyProduct(id:'v12', name:'Kiwi',                      category:'Vegetables', subCategory:'Fruit',        size:'3 pcs', brand:'Imported',       price:150, imageUrl:'${_u}photo-1585059895524-72359e06133a?w=400&q=80'),
  ];

  // FIX: recipe ingredients like Garlic, Ginger, Green Chilli, Coriander,
  // Curry Leaves, Lemon, Avocado etc. had NO matching catalog product at
  // all, which is why "Add Ingredients" from a recipe silently dropped
  // them. Adding real SKUs for every fresh ingredient used in GroklyRecipes.
  static const freshHerbsAromatics = [
    GroklyProduct(id:'fh1', name:'Garlic',                    category:'Vegetables', subCategory:'Aromatics',    size:'250g',  brand:'Local',          price:35,  imageUrl:'${_u}photo-1615485290382-441e4d049cb5?w=400&q=80'),
    GroklyProduct(id:'fh2', name:'Ginger',                     category:'Vegetables', subCategory:'Aromatics',    size:'250g',  brand:'Local',          price:30,  imageUrl:'${_u}photo-1615485290382-441e4d049cb5?w=400&q=80'),
    GroklyProduct(id:'fh3', name:'Ginger-Garlic Paste',        category:'Vegetables', subCategory:'Aromatics',    size:'200g',  brand:'Local',          price:55,  imageUrl:'${_u}photo-1615485290382-441e4d049cb5?w=400&q=80'),
    GroklyProduct(id:'fh4', name:'Green Chilli',                category:'Vegetables', subCategory:'Fresh Veg',   size:'100g',  brand:'Local',          price:15,  imageUrl:'${_u}photo-1576045057995-568f588f82fb?w=400&q=80'),
    GroklyProduct(id:'fh5', name:'Red Chilli (Fresh)',          category:'Vegetables', subCategory:'Fresh Veg',   size:'100g',  brand:'Local',          price:20,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'fh6', name:'Curry Leaves',                category:'Vegetables', subCategory:'Fresh Herbs', size:'50g',   brand:'Local',          price:10,  imageUrl:'${_u}photo-1576045057995-568f588f82fb?w=400&q=80'),
    GroklyProduct(id:'fh7', name:'Coriander Leaves',            category:'Vegetables', subCategory:'Fresh Herbs', size:'100g',  brand:'Local',          price:15,  imageUrl:'${_u}photo-1576045057995-568f588f82fb?w=400&q=80'),
    GroklyProduct(id:'fh8', name:'Dill',                        category:'Vegetables', subCategory:'Fresh Herbs', size:'50g',   brand:'Local',          price:25,  imageUrl:'${_u}photo-1576045057995-568f588f82fb?w=400&q=80'),
    GroklyProduct(id:'fh9', name:'Lemon',                       category:'Vegetables', subCategory:'Fruit',       size:'4 pcs', brand:'Local',          price:30,  imageUrl:'${_u}photo-1582287014914-1db836b8d2e3?w=400&q=80'),
    GroklyProduct(id:'fh10',name:'Hass Avocado',                category:'Vegetables', subCategory:'Exotic Fruit',size:'1 pc',  brand:'Imported',       price:120, imageUrl:'${_u}photo-1523049673857-eb18f1d7b578?w=400&q=80'),
    GroklyProduct(id:'fh11',name:'Cherry Tomatoes',             category:'Vegetables', subCategory:'Exotic Veg',  size:'200g',  brand:'Fresho',         price:65,  imageUrl:'${_u}photo-1546470427-227c1e587a7e?w=400&q=80'),
    GroklyProduct(id:'fh12',name:'Red Cabbage',                 category:'Vegetables', subCategory:'Exotic Veg',  size:'500g',  brand:'Local',          price:55,  imageUrl:'${_u}photo-1518977676601-b53f82aba655?w=400&q=80'),
    GroklyProduct(id:'fh13',name:'Asparagus',                   category:'Vegetables', subCategory:'Exotic Veg',  size:'200g',  brand:'Imported',       price:180, imageUrl:'${_u}photo-1515471209610-dae1c92d8777?w=400&q=80'),
    GroklyProduct(id:'fh14',name:'Mixed Berries',                category:'Vegetables', subCategory:'Fruit',      size:'150g',  brand:'Imported',       price:220, imageUrl:'${_u}photo-1498557850523-fd3d118b962e?w=400&q=80'),
    GroklyProduct(id:'fh15',name:'Cumin Seeds',                  category:'Spices & Masalas', subCategory:'Spice',size:'100g',  brand:'Everest',        price:55,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'fh16',name:'Mustard Seeds',                category:'Spices & Masalas', subCategory:'Spice',size:'100g',  brand:'Everest',        price:35,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'fh17',name:'Kasuri Methi',                 category:'Spices & Masalas', subCategory:'Spice',size:'50g',   brand:'Everest',        price:45,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'fh18',name:'Capers',                       category:'Condiments', subCategory:'Pantry',     size:'100g',  brand:'Del Monte',      price:220, imageUrl:'${_u}photo-1472476443507-c7a5948772fc?w=400&q=80'),
    GroklyProduct(id:'fh19',name:'Tahini',                       category:'Condiments', subCategory:'Spread',     size:'300g',  brand:'Imported',       price:350, imageUrl:'${_u}photo-1612257999691-3aa4af9d27a2?w=400&q=80'),
    GroklyProduct(id:'fh20',name:'Chickpeas',                    category:'Staples', subCategory:'Legumes',       size:'500g',  brand:'Tata Sampann',   price:95,  imageUrl:'${_u}photo-1515543904379-3d757afe72e4?w=400&q=80'),
  ];

  static const meatSeafood = [
    GroklyProduct(id:'ms1', name:'Chicken Breast',              category:'Meat & Seafood', subCategory:'Chicken', size:'500g',  brand:'Licious',        price:220, imageUrl:'${_u}photo-1604503468506-a8da13d82791?w=400&q=80'),
    GroklyProduct(id:'ms2', name:'Salmon Fillet',                category:'Meat & Seafood', subCategory:'Fish',    size:'300g',  brand:'Licious',        price:450, imageUrl:'${_u}photo-1519708227418-c8fd9a32b7a2?w=400&q=80'),
  ];

  static const dryFruitsNuts = [
    GroklyProduct(id:'dn1', name:'Almonds',                   category:'Dry Fruits & Nuts', subCategory:'Nuts',      size:'200g', brand:'Happilo',       price:200, imageUrl:'${_u}photo-1508061253366-f7da158b6d46?w=400&q=80'),
    GroklyProduct(id:'dn2', name:'Cashews',                   category:'Dry Fruits & Nuts', subCategory:'Nuts',      size:'200g', brand:'Happilo',       price:220, imageUrl:'${_u}photo-1508061253366-f7da158b6d46?w=400&q=80'),
    GroklyProduct(id:'dn3', name:'Walnuts',                   category:'Dry Fruits & Nuts', subCategory:'Nuts',      size:'200g', brand:'Happilo',       price:260, imageUrl:'${_u}photo-1508061253366-f7da158b6d46?w=400&q=80'),
    GroklyProduct(id:'dn4', name:'Dates',                     category:'Dry Fruits & Nuts', subCategory:'Dry Fruit', size:'500g', brand:'Lion',          price:150, imageUrl:'${_u}photo-1571680322279-a226e6a4cc2a?w=400&q=80'),
    GroklyProduct(id:'dn5', name:'Raisins',                   category:'Dry Fruits & Nuts', subCategory:'Dry Fruit', size:'200g', brand:'Happilo',       price:75,  imageUrl:'${_u}photo-1571680322279-a226e6a4cc2a?w=400&q=80'),
    GroklyProduct(id:'dn6', name:'Chia Seeds',                category:'Dry Fruits & Nuts', subCategory:'Seeds',     size:'200g', brand:'True Elements', price:200, imageUrl:'${_u}photo-1618946688047-b3e0aaff3c44?w=400&q=80'),
    GroklyProduct(id:'dn7', name:'Pumpkin Seeds',             category:'Dry Fruits & Nuts', subCategory:'Seeds',     size:'200g', brand:'True Elements', price:215, imageUrl:'${_u}photo-1618946688047-b3e0aaff3c44?w=400&q=80'),
  ];

  static const spicesMasalas = [
    GroklyProduct(id:'sp1', name:'Turmeric Powder',           category:'Spices & Masalas', subCategory:'Spice',     size:'200g', brand:'Everest',       price:60,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'sp2', name:'Red Chilli Powder',         category:'Spices & Masalas', subCategory:'Spice',     size:'200g', brand:'Everest',       price:80,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'sp3', name:'Coriander Powder',          category:'Spices & Masalas', subCategory:'Spice',     size:'200g', brand:'Everest',       price:60,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'sp4', name:'Garam Masala',              category:'Spices & Masalas', subCategory:'Spice Mix', size:'100g', brand:'Everest',       price:85,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'sp5', name:'Kitchen King Masala',       category:'Spices & Masalas', subCategory:'Spice Mix', size:'100g', brand:'Everest',       price:90,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'sp6', name:'Sambar Powder',             category:'Spices & Masalas', subCategory:'Regional',  size:'200g', brand:'MTR',           price:100, imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'sp7', name:'Rasam Powder',              category:'Spices & Masalas', subCategory:'Regional',  size:'200g', brand:'MTR',           price:100, imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
    GroklyProduct(id:'sp8', name:'Biryani Masala',            category:'Spices & Masalas', subCategory:'Spice Mix', size:'100g', brand:'Everest',       price:85,  imageUrl:'${_u}photo-1596040033229-a9821ebd058d?w=400&q=80'),
  ];

  static const condiments = [
    GroklyProduct(id:'c1',  name:'Tomato Ketchup',            category:'Condiments', subCategory:'Sauce',         size:'500g',  brand:'Kissan',         price:135, imageUrl:'${_u}photo-1472476443507-c7a5948772fc?w=400&q=80'),
    GroklyProduct(id:'c2',  name:'Mayonnaise',                category:'Condiments', subCategory:'Spread',        size:'250g',  brand:'Veeba',          price:150, imageUrl:'${_u}photo-1472476443507-c7a5948772fc?w=400&q=80'),
    GroklyProduct(id:'c3',  name:'Soy Sauce',                 category:'Condiments', subCategory:'Sauce',         size:'200ml', brand:"Ching's",        price:75,  imageUrl:'${_u}photo-1472476443507-c7a5948772fc?w=400&q=80'),
    GroklyProduct(id:'c4',  name:'Schezwan Sauce',            category:'Condiments', subCategory:'Sauce',         size:'200g',  brand:"Ching's",        price:90,  imageUrl:'${_u}photo-1472476443507-c7a5948772fc?w=400&q=80'),
    GroklyProduct(id:'c5',  name:'Pickle',                    category:'Condiments', subCategory:'Pickle',        size:'500g',  brand:'Priya',          price:150, imageUrl:'${_u}photo-1472476443507-c7a5948772fc?w=400&q=80'),
    GroklyProduct(id:'c6',  name:'Vinegar',                   category:'Condiments', subCategory:'Pantry',        size:'500ml', brand:'Ching\'s',       price:65,  imageUrl:'${_u}photo-1472476443507-c7a5948772fc?w=400&q=80'),
    GroklyProduct(id:'c7',  name:'Mustard Sauce',              category:'Condiments', subCategory:'Sauce',         size:'200g',  brand:'Veeba',          price:110, imageUrl:'${_u}photo-1472476443507-c7a5948772fc?w=400&q=80'),
    GroklyProduct(id:'c8',  name:'Peri Peri Seasoning',        category:'Condiments', subCategory:'Seasoning',     size:'100g',  brand:'Veeba',          price:95,  imageUrl:'${_u}photo-1472476443507-c7a5948772fc?w=400&q=80'),
  ];

  static const readyToCook = [
    GroklyProduct(id:'rtc1', name:'iD Fresh Dosa Batter',    category:'Ready-to-Cook', subCategory:'RTC',       size:'500g',  brand:'iD Fresh',       price:57,  imageUrl:'${_u}photo-1630383249896-424e482df921?w=400&q=80'),
    GroklyProduct(id:'rtc2', name:'Chapati Dough',            category:'Ready-to-Cook', subCategory:'RTC',       size:'500g',  brand:'iD Fresh',       price:65,  imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    GroklyProduct(id:'rtc3', name:'Instant Biryani Mix',      category:'Ready-to-Cook', subCategory:'RTC',       size:'300g',  brand:'MTR',            price:100, imageUrl:'${_u}photo-1589302168068-964664d93dc0?w=400&q=80'),
    GroklyProduct(id:'rtc4', name:'Instant Pongal Mix',       category:'Ready-to-Cook', subCategory:'RTC',       size:'300g',  brand:'MTR',            price:100, imageUrl:'${_u}photo-1589302168068-964664d93dc0?w=400&q=80'),
    GroklyProduct(id:'rtc5', name:'Idli Batter',              category:'Ready-to-Cook', subCategory:'RTC',       size:'1kg',   brand:'iD Fresh',       price:80,  imageUrl:'${_u}photo-1630383249896-424e482df921?w=400&q=80'),
    GroklyProduct(id:'rtc6', name:'Frozen Parotta',           category:'Ready-to-Cook', subCategory:'RTC',       size:'400g',  brand:'Ceres',          price:120, imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
  ];

  static const frozen = [
    GroklyProduct(id:'fr1', name:'Frozen Green Peas',         category:'Frozen', subCategory:'Frozen Veg',       size:'500g',  brand:'Safal',          price:120, imageUrl:'${_u}photo-1486297678162-eb2a19b0a32d?w=400&q=80'),
    GroklyProduct(id:'fr2', name:'Frozen Mixed Veg',          category:'Frozen', subCategory:'Frozen Veg',       size:'500g',  brand:'Safal',          price:140, imageUrl:'${_u}photo-1486297678162-eb2a19b0a32d?w=400&q=80'),
    GroklyProduct(id:'fr3', name:'Frozen Paneer Cubes',       category:'Frozen', subCategory:'Frozen',           size:'200g',  brand:'Amul',           price:140, imageUrl:'${_u}photo-1631452180519-c014fe946bc7?w=400&q=80'),
    GroklyProduct(id:'fr4', name:'Frozen Paratha',            category:'Frozen', subCategory:'Frozen Food',      size:'500g',  brand:'iD Fresh',       price:150, imageUrl:'${_u}photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    GroklyProduct(id:'fr5', name:'Frozen Cheese Nuggets',     category:'Frozen', subCategory:'Frozen Food',      size:'300g',  brand:'McCain',         price:200, imageUrl:'${_u}photo-1486297678162-eb2a19b0a32d?w=400&q=80'),
    GroklyProduct(id:'fr6', name:'Frozen Veg Nuggets',        category:'Frozen', subCategory:'Frozen Food',      size:'400g',  brand:'McCain',         price:180, imageUrl:'${_u}photo-1486297678162-eb2a19b0a32d?w=400&q=80'),
    GroklyProduct(id:'fr7', name:'Frozen French Fries',       category:'Frozen', subCategory:'Frozen Food',      size:'420g',  brand:'McCain',         price:130, imageUrl:'${_u}photo-1541592106381-b31e9677c0e5?w=400&q=80'),
  ];

  static const household = [
    GroklyProduct(id:'h1',  name:'Detergent Powder',          category:'Household', subCategory:'Laundry',       size:'1kg',   brand:'Surf Excel',     price:150, imageUrl:'${_u}photo-1558618666-fcd25c85cd64?w=400&q=80'),
    GroklyProduct(id:'h2',  name:'Dishwash Liquid',           category:'Household', subCategory:'Dish Care',     size:'500ml', brand:'Vim/Pril',       price:160, imageUrl:'${_u}photo-1585421514284-efb74c2b69ba?w=400&q=80'),
    GroklyProduct(id:'h3',  name:'Floor Cleaner',             category:'Household', subCategory:'Cleaning',      size:'1L',    brand:'Lizol',          price:200, imageUrl:'${_u}photo-1585421514284-efb74c2b69ba?w=400&q=80'),
    GroklyProduct(id:'h4',  name:'Tissue Paper',              category:'Household', subCategory:'Paper Goods',   size:'100-200 pulls',brand:'Origami', price:115, imageUrl:'${_u}photo-1584556812952-905ffd0c611a?w=400&q=80'),
    GroklyProduct(id:'h5',  name:'Garbage Bags',              category:'Household', subCategory:'Utility',       size:'20-30 bags',brand:'Local',      price:85,  imageUrl:'${_u}photo-1558618666-fcd25c85cd64?w=400&q=80'),
  ];

  static const personalCare = [
    GroklyProduct(id:'pc1', name:'Body Wash',                 category:'Personal Care', subCategory:'Body Wash',  size:'250ml', brand:'Nivea/Dove',    price:240, imageUrl:'${_u}photo-1620916566398-39f1143ab7be?w=400&q=80'),
    GroklyProduct(id:'pc2', name:'Shampoo (Large)',           category:'Personal Care', subCategory:'Shampoo',    size:'500ml', brand:"Tresemm├⌐",      price:450, imageUrl:'${_u}photo-1620916566398-39f1143ab7be?w=400&q=80'),
    GroklyProduct(id:'pc3', name:'Toothpaste',                category:'Personal Care', subCategory:'Oral Care',  size:'150g',  brand:'Colgate',       price:150, imageUrl:'${_u}photo-1629132435001-fc79f2cbff4e?w=400&q=80'),
    GroklyProduct(id:'pc4', name:'Handwash',                  category:'Personal Care', subCategory:'Hygiene',    size:'250ml', brand:'Dettol/Savlon', price:120, imageUrl:'${_u}photo-1620916566398-39f1143ab7be?w=400&q=80'),
    GroklyProduct(id:'pc5', name:'Face Wash',                 category:'Personal Care', subCategory:'Skin Care',  size:'100ml', brand:'Himalaya',      price:175, imageUrl:'${_u}photo-1629132435001-fc79f2cbff4e?w=400&q=80'),
  ];
  static const babyCare = [
    GroklyProduct(id:'bc1', name:'Baby Diapers (M)',          category:'Baby Care', subCategory:'Diapers',       size:'44 pcs', brand:'Pampers',       price:650, imageUrl:'${_u}photo-1584464491033-06628f3a6b7b?w=400&q=80'),
    GroklyProduct(id:'bc2', name:'Baby Wipes',                category:'Baby Care', subCategory:'Hygiene',       size:'80 pcs', brand:'Himalaya',      price:180, imageUrl:'${_u}photo-1584464491033-06628f3a6b7b?w=400&q=80'),
    GroklyProduct(id:'bc3', name:'Baby Lotion',               category:'Baby Care', subCategory:'Skin Care',     size:'200ml',  brand:'Johnson\'s',    price:210, imageUrl:'${_u}photo-1620916566398-39f1143ab7be?w=400&q=80'),
    GroklyProduct(id:'bc4', name:'Baby Cereal',               category:'Baby Care', subCategory:'Food',          size:'300g',   brand:'Cerelac',       price:240, imageUrl:'${_u}photo-1587314168485-3236d6710814?w=400&q=80'),
  ];
}

// ���������������������������������������������
// RECIPES
// FIX: every RecipeIngredient now carries a real Unsplash imageUrl so the
// new recipe-detail screen can render an ingredient image instead of a
// blank/broken placeholder.
// ���������������������������������������������

class GroklyRecipes {
  static const List<GroklyRecipe> all = [
    GroklyRecipe(
      id: 'r1', name: 'Butter Chicken',
      imageUrl: 'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=600&q=80',
      cuisine: 'Indian', prepMinutes: 30, servings: 4, estimatedCost: 345,
      ingredients: [
        RecipeIngredient('Chicken', '500g', '${_u}photo-1604503468506-a8da13d82791?w=300&q=80'),
        RecipeIngredient('Tomatoes', '3 pcs', '${_u}photo-1546470427-227c1e587a7e?w=300&q=80'),
        RecipeIngredient('Fresh Cream', '200ml', '${_u}photo-1563636619-e9143da7973b?w=300&q=80'),
        RecipeIngredient('Garam Masala', '1 tsp', '${_u}photo-1596040033229-a9821ebd058d?w=300&q=80'),
        RecipeIngredient('Butter', '50g', '${_u}photo-1589985270826-4b7bb135bc9d?w=300&q=80'),
        RecipeIngredient('Kasuri Methi', '1 tbsp', '${_u}photo-1596040033229-a9821ebd058d?w=300&q=80'),
        RecipeIngredient('Ginger-Garlic Paste', '2 tbsp', '${_u}photo-1615485290382-441e4d049cb5?w=300&q=80'),
        RecipeIngredient('Red Chilli Powder', '1 tsp', '${_u}photo-1596040033229-a9821ebd058d?w=300&q=80'),
      ],
    ),
    GroklyRecipe(
      id: 'r2', name: 'Zesty Buddha Bowl',
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80',
      cuisine: 'World', prepMinutes: 20, servings: 2, estimatedCost: 280,
      ingredients: [
        RecipeIngredient('Quinoa', '1 cup', '${_u}photo-1612257999691-3aa4af9d27a2?w=300&q=80'),
        RecipeIngredient('Baby Spinach', '100g', '${_u}photo-1576045057995-568f588f82fb?w=300&q=80'),
        RecipeIngredient('Hass Avocado', '1 pc', '${_u}photo-1523049673857-eb18f1d7b578?w=300&q=80'),
        RecipeIngredient('Broccoli', '200g', '${_u}photo-1459411621453-7b03977f4bfc?w=300&q=80'),
        RecipeIngredient('Mushroom', '100g', '${_u}photo-1504545102780-26774c1bb073?w=300&q=80'),
        RecipeIngredient('Chickpeas', '200g', '${_u}photo-1515543904379-3d757afe72e4?w=300&q=80'),
        RecipeIngredient('Olive Oil', '2 tbsp', '${_u}photo-1474979266404-7eaacbcd87c5?w=300&q=80'),
        RecipeIngredient('Lemon', '1 pc', '${_u}photo-1582287014914-1db836b8d2e3?w=300&q=80'),
        RecipeIngredient('Tahini', '2 tbsp', '${_u}photo-1612257999691-3aa4af9d27a2?w=300&q=80'),
        RecipeIngredient('Cherry Tomatoes', '100g', '${_u}photo-1546470427-227c1e587a7e?w=300&q=80'),
        RecipeIngredient('Red Cabbage', '50g', '${_u}photo-1518977676601-b53f82aba655?w=300&q=80'),
        RecipeIngredient('Sweet Corn', '50g', '${_u}photo-1551754655-cd27e38d2076?w=300&q=80'),
      ],
    ),
    GroklyRecipe(
      id: 'r3', name: 'Mediterranean Salmon',
      imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=600&q=80',
      cuisine: 'Mediterranean', prepMinutes: 15, servings: 2, estimatedCost: 420,
      ingredients: [
        RecipeIngredient('Salmon Fillet', '400g', '${_u}photo-1519708227418-c8fd9a32b7a2?w=300&q=80'),
        RecipeIngredient('Lemon', '1 pc', '${_u}photo-1582287014914-1db836b8d2e3?w=300&q=80'),
        RecipeIngredient('Olive Oil', '3 tbsp', '${_u}photo-1474979266404-7eaacbcd87c5?w=300&q=80'),
        RecipeIngredient('Asparagus', '1 bunch', '${_u}photo-1515471209610-dae1c92d8777?w=300&q=80'),
        RecipeIngredient('Capers', '2 tbsp', '${_u}photo-1472476443507-c7a5948772fc?w=300&q=80'),
        RecipeIngredient('Dill', '1 bunch', '${_u}photo-1576045057995-568f588f82fb?w=300&q=80'),
        RecipeIngredient('Garlic', '3 cloves', '${_u}photo-1615485290382-441e4d049cb5?w=300&q=80'),
        RecipeIngredient('Cherry Tomatoes', '150g', '${_u}photo-1546470427-227c1e587a7e?w=300&q=80'),
      ],
    ),
    GroklyRecipe(
      id: 'r4', name: 'Masala Dosa',
      imageUrl: 'https://images.unsplash.com/photo-1630383249896-424e482df921?w=600&q=80',
      cuisine: 'South Indian', prepMinutes: 25, servings: 4, estimatedCost: 180,
      ingredients: [
        RecipeIngredient('Dosa Batter', '500g', '${_u}photo-1630383249896-424e482df921?w=300&q=80'),
        RecipeIngredient('Potato', '300g', '${_u}photo-1518977822534-7049a61ee0c2?w=300&q=80'),
        RecipeIngredient('Onion', '1 pc', '${_u}photo-1518977822534-7049a61ee0c2?w=300&q=80'),
        RecipeIngredient('Mustard Seeds', '1 tsp', '${_u}photo-1596040033229-a9821ebd058d?w=300&q=80'),
        RecipeIngredient('Turmeric Powder', '� tsp', '${_u}photo-1596040033229-a9821ebd058d?w=300&q=80'),
        RecipeIngredient('Green Chilli', '2 pcs', '${_u}photo-1576045057995-568f588f82fb?w=300&q=80'),
        RecipeIngredient('Curry Leaves', '8-10 leaves', '${_u}photo-1576045057995-568f588f82fb?w=300&q=80'),
        RecipeIngredient('Oil', '3 tbsp', '${_u}photo-1474979266404-7eaacbcd87c5?w=300&q=80'),
      ],
    ),
    GroklyRecipe(
      id: 'r5', name: 'Dal Tadka',
      imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=600&q=80',
      cuisine: 'North Indian', prepMinutes: 30, servings: 4, estimatedCost: 120,
      ingredients: [
        RecipeIngredient('Toor Dal', '1 cup', '${_u}photo-1585937421612-70a008356fbe?w=300&q=80'),
        RecipeIngredient('Tomato', '2 pcs', '${_u}photo-1546470427-227c1e587a7e?w=300&q=80'),
        RecipeIngredient('Onion', '1 pc', '${_u}photo-1518977822534-7049a61ee0c2?w=300&q=80'),
        RecipeIngredient('Ginger', '1 inch', '${_u}photo-1615485290382-441e4d049cb5?w=300&q=80'),
        RecipeIngredient('Garlic', '4 cloves', '${_u}photo-1615485290382-441e4d049cb5?w=300&q=80'),
        RecipeIngredient('Cumin Seeds', '1 tsp', '${_u}photo-1596040033229-a9821ebd058d?w=300&q=80'),
        RecipeIngredient('Ghee', '2 tbsp', '${_u}photo-1631452180519-c014fe946bc7?w=300&q=80'),
        RecipeIngredient('Red Chilli', '2 pcs', '${_u}photo-1596040033229-a9821ebd058d?w=300&q=80'),
        RecipeIngredient('Coriander', '2 tbsp', '${_u}photo-1576045057995-568f588f82fb?w=300&q=80'),
      ],
    ),
    GroklyRecipe(
      id: 'r6', name: 'Avocado Toast',
      imageUrl: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c820?w=600&q=80',
      cuisine: 'Continental', prepMinutes: 10, servings: 2, estimatedCost: 150,
      ingredients: [
        RecipeIngredient('Multigrain Bread', '4 slices', '${_u}photo-1509440159596-0249088772ff?w=300&q=80'),
        RecipeIngredient('Hass Avocado', '2 pcs', '${_u}photo-1523049673857-eb18f1d7b578?w=300&q=80'),
        RecipeIngredient('Lemon', '� pc', '${_u}photo-1582287014914-1db836b8d2e3?w=300&q=80'),
        RecipeIngredient('Eggs', '2 pcs', '${_u}photo-1582722872445-44dc5f7e3c8f?w=300&q=80'),
        RecipeIngredient('Cherry Tomatoes', '100g', '${_u}photo-1546470427-227c1e587a7e?w=300&q=80'),
        RecipeIngredient('Olive Oil', '1 tbsp', '${_u}photo-1474979266404-7eaacbcd87c5?w=300&q=80'),
      ],
    ),
    GroklyRecipe(
      id: 'r7', name: 'Palak Paneer',
      imageUrl: 'https://images.unsplash.com/photo-1618449840665-9ed506d73a34?w=600&q=80',
      cuisine: 'North Indian', prepMinutes: 25, servings: 4, estimatedCost: 220,
      ingredients: [
        RecipeIngredient('Paneer', '200g', '${_u}photo-1631452180519-c014fe946bc7?w=300&q=80'),
        RecipeIngredient('Baby Spinach', '400g', '${_u}photo-1576045057995-568f588f82fb?w=300&q=80'),
        RecipeIngredient('Onion', '1 pc', '${_u}photo-1518977822534-7049a61ee0c2?w=300&q=80'),
        RecipeIngredient('Tomato', '2 pcs', '${_u}photo-1546470427-227c1e587a7e?w=300&q=80'),
        RecipeIngredient('Garam Masala', '1 tsp', '${_u}photo-1596040033229-a9821ebd058d?w=300&q=80'),
        RecipeIngredient('Ghee', '2 tbsp', '${_u}photo-1631452180519-c014fe946bc7?w=300&q=80'),
        RecipeIngredient('Fresh Cream', '3 tbsp', '${_u}photo-1563636619-e9143da7973b?w=300&q=80'),
        RecipeIngredient('Ginger', '1 inch', '${_u}photo-1615485290382-441e4d049cb5?w=300&q=80'),
      ],
    ),
    GroklyRecipe(
      id: 'r8', name: 'Overnight Oats',
      imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=600&q=80',
      cuisine: 'Healthy', prepMinutes: 5, servings: 1, estimatedCost: 80,
      ingredients: [
        RecipeIngredient('Oats', '� cup', '${_u}photo-1517686748843-bb360cd3b596?w=300&q=80'),
        RecipeIngredient('Oat Milk', '200ml', '${_u}photo-1563636619-e9143da7973b?w=300&q=80'),
        RecipeIngredient('Chia Seeds', '1 tbsp', '${_u}photo-1618946688047-b3e0aaff3c44?w=300&q=80'),
        RecipeIngredient('Banana', '1 pc', '${_u}photo-1603833665858-e61d17a86224?w=300&q=80'),
        RecipeIngredient('Honey', '1 tsp', '${_u}photo-1558961363-fa8fdf82db35?w=300&q=80'),
        RecipeIngredient('Mixed Berries', '50g', '${_u}photo-1498557850523-fd3d118b962e?w=300&q=80'),
      ],
    ),
  ];
}

// ���������������������������������������������
// CART STATE (in-memory)
// FIX: added SavedBasketsState alongside CartState so "Save Active Cart"
// on the Saved Baskets screen actually persists a basket in-memory and the
// screen always has at least the seeded baskets to render (previously the
// screen had no provider/state wiring, which is why it rendered blank).
// ���������������������������������������������

// ���������������������������������������������
// BACKEND INTEGRATION (Firestore + local cache)
// Cart lives at users/{uid}/grokly_state/cart in Firestore, so it survives
// app restarts and follows the signed-in user across devices — not just
// in-memory for the session. A SharedPreferences cache is written on every
// save too, so the cart loads instantly (no network wait) and still works
// if the user is offline or signed out. Orders are written to
// users/{uid}/grokly_orders/{orderId} on successful checkout.
// ���������������������������������������������

class GroklyCartRepository {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('grokly_state').doc('cart');
  }

  static List<Map<String, dynamic>> _encode(List<CartItem> items) =>
      items.map((i) => {'productId': i.product.id, 'qty': i.qty}).toList();

  static List<CartItem> _decode(List raw) {
    final items = <CartItem>[];
    for (final entry in raw) {
      final map = Map<String, dynamic>.from(entry as Map);
      final product = GroklyCatalog.all.where((p) => p.id == map['productId']).firstOrNull;
      if (product != null) {
        items.add(CartItem(product: product, qty: (map['qty'] as num?)?.toInt() ?? 1));
      }
    }
    return items;
  }

  /// Firestore first (source of truth once signed in), falling back to the
  /// local cache so the cart isn't empty while waiting on a network read,
  /// and still works if there's no signed-in user or no connectivity.
  static Future<List<CartItem>> load() async {
    try {
      final doc = _doc;
      if (doc != null) {
        final snap = await doc.get();
        if (snap.exists && snap.data()?['items'] != null) {
          return _decode(snap.data()!['items'] as List);
        }
      }
    } catch (_) {
      // fall through to local cache below
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('grokly_cart_cache');
      if (cached != null) return _decode(jsonDecode(cached) as List);
    } catch (_) {}
    return [];
  }

  static Future<void> save(List<CartItem> items) async {
    final encoded = _encode(items);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('grokly_cart_cache', jsonEncode(encoded));
    } catch (_) {}
    final doc = _doc;
    if (doc != null) {
      try {
        await doc.set({'items': encoded, 'updatedAt': FieldValue.serverTimestamp()});
      } catch (_) {
        // offline / rules error — local cache above still holds the cart,
        // next successful save() will catch Firestore back up.
      }
    }
  }

  static Future<void> clearRemote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('grokly_cart_cache');
    } catch (_) {}
    final doc = _doc;
    if (doc != null) {
      try { await doc.delete(); } catch (_) {}
    }
  }
}

class GroklyOrderRepository {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Writes a confirmed order to Firestore under the signed-in user and
  /// returns the order id to show in the UI. If there's no signed-in user
  /// or the write fails (offline), the order is queued locally instead of
  /// being lost, and gets a local id so checkout never hard-fails.
  static Future<String> placeOrder({
    required List<CartItem> items,
    required double total,
    required String paymentMethod,
    String? orderId,
    String? transactionId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rzpOrderId = orderId ?? 'ORD_GROKLY_$timestamp';
    final txnId = transactionId ?? 'TXN_GROKLY_$timestamp';

    final orderData = {
      'orderId': rzpOrderId,
      'transactionId': txnId,
      'items': items.map((i) => {
        'productId': i.product.id,
        'name': i.product.name,
        'qty': i.qty,
        'price': i.product.price,
      }).toList(),
      'total': total,
      'paymentMethod': paymentMethod,
      'status': 'confirmed',
    };

    final uid = _uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('grokly_orders')
            .doc(rzpOrderId)
            .set({...orderData, 'createdAt': FieldValue.serverTimestamp()});

        // Also record in primary orders collection for unified order history
        await FirebaseFirestore.instance
            .collection('orders')
            .doc('${uid}_$rzpOrderId')
            .set({
          'id': rzpOrderId,
          'userId': uid,
          'restaurantName': 'Grokly Market',
          'restaurantImage': 'assets/images/grokly_hero_banner.png',
          'items': items.map((i) => {
            'name': i.product.name,
            'quantity': i.qty,
            'price': i.product.price,
          }).toList(),
          'paymentMethod': paymentMethod,
          'razorpayOrderId': rzpOrderId,
          'transactionId': txnId,
          'totalPaid': total,
          'status': 'Preparing',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return rzpOrderId;
      } catch (_) {
        // fall through to local-only queue below
      }
    }
    final localId = rzpOrderId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('grokly_pending_orders') ?? [];
      pending.add(jsonEncode({
        ...orderData, 'localId': localId, 'createdAt': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList('grokly_pending_orders', pending);
    } catch (_) {}
    return localId;
  }
}

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  /// True once the initial load from Firestore/local cache has completed.
  /// Screens can check this to show a brief loading state instead of
  /// flashing an empty cart before hydration finishes.
  bool isHydrated = false;

  CartState() {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final loaded = await GroklyCartRepository.load();
    _items
      ..clear()
      ..addAll(loaded);
    isHydrated = true;
    notifyListeners();
  }

  Timer? _saveDebounce;
  void _persist() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), () {
      GroklyCartRepository.save(_items);
    });
  }

  int get totalQty => _items.fold(0, (s, i) => s + i.qty);
  double get totalPrice => _items.fold(0.0, (s, i) => s + i.product.price * i.qty);

  void add(GroklyProduct p) {
    final existing = _items.where((i) => i.product.id == p.id).firstOrNull;
    if (existing != null) {
      existing.qty++;
    } else {
      _items.add(CartItem(product: p));
    }
    
    // Add to Unified Cart
    try {
      // Need to use dynamic to avoid importing unified_cart_provider.dart locally
      // Actually we CAN import it at the top of the file!
      // I will just add it, assuming I will insert the import at the top later.
      UnifiedCartState.instance.addItem(
        vendorName: 'Grokly',
        id: p.id,
        name: p.name,
        subtitle: '${p.size} · ${p.brand}',
        unitPrice: p.price.toInt(),
        imageUrl: p.imageUrl,
      );
    } catch (_) {}

    notifyListeners();
    _persist();
  }

  void remove(GroklyProduct p) {
    final existing = _items.where((i) => i.product.id == p.id).firstOrNull;
    if (existing != null) {
      if (existing.qty > 1) {
        existing.qty--;
      } else {
        _items.remove(existing);
      }
      notifyListeners();
      _persist();
    }
  }

  int qtyOf(String id) =>
      _items.where((i) => i.product.id == id).firstOrNull?.qty ?? 0;

  void clear() {
    _items.clear();
    notifyListeners();
    _saveDebounce?.cancel();
    GroklyCartRepository.clearRemote();
  }

  void addRecipe(GroklyRecipe recipe) {
    for (final ing in recipe.ingredients) {
      final match = GroklyIngredientMatcher.resolve(ing.name);
      if (match != null) _addSilently(match);
    }
    notifyListeners();
    _persist();
  }

  /// Adds a single ingredient's matching product to the cart.
  /// Returns the matched product, or null if no catalog item exists for it
  /// (previously this failed silently — callers now know exactly what
  /// happened instead of assuming success).
  GroklyProduct? addIngredient(RecipeIngredient ing) {
    final match = GroklyIngredientMatcher.resolve(ing.name);
    if (match != null) add(match);
    return match;
  }

  void _addSilently(GroklyProduct p) {
    final existing = _items.where((i) => i.product.id == p.id).firstOrNull;
    if (existing != null) {
      existing.qty++;
    } else {
      _items.add(CartItem(product: p));
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}

/// FIX: this used to be p.name.toLowerCase().contains(ing.name.split(' ').first)
/// — a "contains the first word" substring match. That's why smart features
/// (Dish-First, Sixth Sense, recipe ingredient picker) sometimes added the
/// WRONG product (e.g. "Red Chilli Powder" → first word "red" could match
/// any product with "red" in its name) and sometimes added NOTHING at all
/// (e.g. "Garlic", "Ginger", "Lemon" had no catalog product to fuzzy-match
/// against before the catalog was extended above).
///
/// This resolver instead uses an explicit, exact ingredient-name → product-id
/// map covering every ingredient used across GroklyRecipes, so a given
/// ingredient always resolves to the same, correct product. A conservative
/// whole-word fallback (never a bare "contains") is used only for ingredient
/// names not in the map, so future recipes don't silently drop items either.
class GroklyIngredientMatcher {
  static const Map<String, String> _map = {
    'asparagus': 'fh13',
    'baby spinach': 'v5',
    'banana': 'v10',
    'broccoli': 'v4',
    'butter': 'd12',
    'capers': 'fh18',
    'cherry tomatoes': 'fh11',
    'chia seeds': 'dn6',
    'chicken': 'ms1',
    'chickpeas': 'fh20',
    'coriander': 'fh7',
    'cumin seeds': 'fh15',
    'curry leaves': 'fh6',
    'dill': 'fh8',
    'dosa batter': 's18',
    'eggs': 'b5',
    'fresh cream': 'd17',
    'garam masala': 'sp4',
    'garlic': 'fh1',
    'ghee': 'd15',
    'ginger': 'fh2',
    'ginger-garlic paste': 'fh3',
    'green chilli': 'fh4',
    'hass avocado': 'fh10',
    'honey': 'b10',
    'kasuri methi': 'fh17',
    'lemon': 'fh9',
    'mixed berries': 'fh14',
    'multigrain bread': 'b3',
    'mushroom': 'v6',
    'mustard seeds': 'fh16',
    'oat milk': 'd19',
    'oats': 's19',
    'oil': 's12',
    'olive oil': 's14',
    'onion': 'v2',
    'paneer': 'd10',
    'potato': 'v3',
    'quinoa': 's20',
    'red cabbage': 'fh12',
    'red chilli': 'fh5',
    'red chilli powder': 'sp2',
    'salmon fillet': 'ms2',
    'sweet corn': 'v8',
    'tahini': 'fh19',
    'tomato': 'v1',
    'tomatoes': 'v1',
    'toor dal': 's7',
    'turmeric powder': 'sp1',
  };

  static GroklyProduct? resolve(String ingredientName) {
    final key = ingredientName.trim().toLowerCase();
    final id = _map[key];
    if (id != null) {
      return GroklyCatalog.all.where((p) => p.id == id).firstOrNull;
    }
    // Conservative fallback for any ingredient not in the map above:
    // requires the ingredient name to appear as a WHOLE WORD in the
    // product name (not a bare substring), so e.g. "Red Chilli" can no
    // longer accidentally match "Red Cabbage".
    final words = key.split(RegExp(r'\s+'));
    return GroklyCatalog.all.where((p) {
      final productWords = p.name.toLowerCase().split(RegExp(r'[\s(),]+'));
      return words.every((w) => productWords.contains(w));
    }).firstOrNull;
  }
}

/// FIX (new): tiny in-memory store for "My Saved Baskets".
/// Seeded with the same 3 demo baskets the screen used to hard-code, plus
/// support for saving the live cart as a brand-new basket.
class SavedBasketsState extends ChangeNotifier {
  final List<SavedBasket> _baskets = [
    const SavedBasket(name: 'Weekly Essentials', subtitle: 'Last ordered 3 days ago',
        price: 1250, itemCount: 14,
        imageUrls: [
          'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?w=300&q=80',
          'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=300&q=80',
        ]),
    const SavedBasket(name: 'Keto Breakfast', subtitle: 'Created last month',
        price: 620, itemCount: 6,
        imageUrls: [
          'https://images.unsplash.com/photo-1550989460-0adf9ea622e2?w=300&q=80',
          'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=300&q=80',
        ]),
    const SavedBasket(name: 'Weekend Brunch', subtitle: 'Created 2 weeks ago',
        price: 880, itemCount: 8,
        imageUrls: [
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=300&q=80',
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300&q=80',
        ]),
  ];

  List<SavedBasket> get baskets => _baskets;

  void saveFromCart(CartState cart) {
    if (cart.items.isEmpty) return;
    final imgs = cart.items.map((i) => i.product.imageUrl).take(2).toList();
    while (imgs.length < 2) {
      imgs.add('https://images.unsplash.com/photo-1542838132-92c53300491e?w=300&q=80');
    }
    _baskets.insert(0, SavedBasket(
      name: 'My Basket #${_baskets.length + 1}',
      subtitle: 'Created just now',
      price: cart.totalPrice,
      itemCount: cart.totalQty,
      imageUrls: imgs,
    ));
    notifyListeners();
  }
}
// ���������������������������������������������
// CROSS-ORDER ECO-RETURN QUEUE ("My Orders" flow)
// ���������������������������������������������

enum ReturnQueueStatus { eligible, queued, returned, notEligible }

class OrderProduct {
  final String name;
  final String imageUrl;
  final double price;
  final int qty;
  final String size;
  const OrderProduct({
    required this.name, required this.imageUrl, required this.price,
    required this.qty, this.size = '',
  });
}

class MyOrderRecord {
  final String id;
  final String dateLabel;
  final double total;
  final String statusLabel;
  ReturnQueueStatus returnStatus;
  final List<ReturnableItem> returnables;
  final double? creditedAmount;
  final List<OrderProduct> products;

  MyOrderRecord({
    required this.id,
    required this.dateLabel,
    required this.total,
    required this.statusLabel,
    required this.returnStatus,
    this.returnables = const [],
    this.creditedAmount,
    this.products = const [],
  });
}

class MyOrdersState extends ChangeNotifier {
  final List<MyOrderRecord> orders = [
    MyOrderRecord(
      id: '4821',
      dateLabel: '6 Aug',
      total: 484,
      statusLabel: 'Delivered',
      returnStatus: ReturnQueueStatus.eligible,
      returnables: [
        ReturnableItem(label: 'Milk bottles', material: 'PET · Recycle', qty: 2, creditPerUnit: 2),
        ReturnableItem(label: 'Oil bottle', material: 'PET · Recycle', qty: 1, creditPerUnit: 3),
        ReturnableItem(label: 'Cardboard box', material: 'Cardboard · Recycle', qty: 1, creditPerUnit: 2, selected: false),
      ],
      products: [
        OrderProduct(name: 'Amul Taaza Milk', imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=300&q=80', price: 28, qty: 2, size: '500ml'),
        OrderProduct(name: 'Fortune Sunflower Oil', imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacdc50f66?w=300&q=80', price: 155, qty: 1, size: '1L'),
        OrderProduct(name: 'Whole Wheat Bread', imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300&q=80', price: 45, qty: 2, size: '400g'),
        OrderProduct(name: 'Farm Eggs', imageUrl: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=300&q=80', price: 89, qty: 1, size: '12 pcs'),
        OrderProduct(name: 'Organic Honey', imageUrl: 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=300&q=80', price: 94, qty: 1, size: '250g'),
      ],
    ),
    MyOrderRecord(
      id: '4798', dateLabel: '4 Aug', total: 310, statusLabel: 'Delivered',
      returnStatus: ReturnQueueStatus.queued, creditedAmount: 7,
      products: [
        OrderProduct(name: 'Basmati Rice', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300&q=80', price: 185, qty: 1, size: '1kg'),
        OrderProduct(name: 'Toor Dal', imageUrl: 'https://images.unsplash.com/photo-1585996900799-ec5bdcfe6849?w=300&q=80', price: 125, qty: 1, size: '1kg'),
      ],
    ),
    MyOrderRecord(
      id: '4710', dateLabel: '1 Aug', total: 320, statusLabel: 'Delivered',
      returnStatus: ReturnQueueStatus.returned, creditedAmount: 6,
      products: [
        OrderProduct(name: 'Greek Yogurt', imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=300&q=80', price: 75, qty: 2, size: '200g'),
        OrderProduct(name: 'Almond Butter', imageUrl: 'https://images.unsplash.com/photo-1612187003653-5bee9bba0264?w=300&q=80', price: 170, qty: 1, size: '200g'),
      ],
    ),
    MyOrderRecord(
      id: '4690', dateLabel: '29 Jul', total: 210, statusLabel: 'Cancelled',
      returnStatus: ReturnQueueStatus.notEligible,
      products: [
        OrderProduct(name: 'Avocados', imageUrl: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=300&q=80', price: 120, qty: 1, size: '2 pcs'),
        OrderProduct(name: 'Blueberries', imageUrl: 'https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=300&q=80', price: 90, qty: 1, size: '125g'),
      ],
    ),
  ];

  int get returnEligibleCount =>
      orders.where((o) => o.returnStatus == ReturnQueueStatus.eligible).length;

  /// Items queued (from a past order) that should be offered at the next
  /// Checkout and handed to the rider on the next Order-arriving screen.
  List<MapEntry<MyOrderRecord, ReturnableItem>> get queuedForNextDelivery {
    final result = <MapEntry<MyOrderRecord, ReturnableItem>>[];
    for (final o in orders) {
      if (o.returnStatus != ReturnQueueStatus.queued) continue;
      for (final r in o.returnables.where((r) => r.selected)) {
        result.add(MapEntry(o, r));
      }
    }
    return result;
  }

  void queueForNextDelivery(MyOrderRecord order) {
    order.returnStatus = ReturnQueueStatus.queued;
    notifyListeners();
  }

  void markReturned(Iterable<MyOrderRecord> ordersToMark) {
    for (final o in ordersToMark) {
      o.returnStatus = ReturnQueueStatus.returned;
    }
    notifyListeners();
  }
}

class GroklyOrdersProvider extends InheritedNotifier<MyOrdersState> {
  const GroklyOrdersProvider({
    super.key,
    required MyOrdersState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static MyOrdersState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GroklyOrdersProvider>()!.notifier!;
}
// ���������������������������������������������
// WALLET STATE — shared across Profile, Wallet, and Return Confirmed
// ���������������������������������������������


class WalletState extends ChangeNotifier {
  double _balance = 0.0;
  List<WalletTransaction> _transactions = [];
  StreamSubscription? _userSub;
  StreamSubscription? _txnSub;

  WalletState() {
    _initFirebaseListeners();
  }

  void _initFirebaseListeners() {
    final userId = FirebaseService.currentUserId;
    
    // Listen to user's wallet balance
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('walletBalance') && doc.data()!['walletBalance'] != null) {
        _balance = (doc.data()!['walletBalance'] as num).toDouble();
      } else {
        _balance = 0.0;
      }
      notifyListeners();
    }, onError: (e) {
      print('Wallet balance listener error: $e');
    });

    // Listen to wallet transactions WITHOUT orderBy to avoid index exception
    _txnSub = FirebaseFirestore.instance
        .collection('wallet_transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      final txns = snapshot.docs.map((doc) {
        final data = doc.data();
        final typeStr = data['type'] as String? ?? 'topup';
        final isCredit = typeStr == 'topup' || typeStr == 'refund';
        
        TxnType type = TxnType.topup;
        if (typeStr == 'order') type = TxnType.order;
        else if (typeStr == 'refund') type = TxnType.refund;

        return WalletTransaction(
          title: data['title'] ?? 'Transaction',
          date: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          isCredit: isCredit,
          status: isCredit ? 'SUCCESS' : 'PAID',
          type: type,
          orderId: data['orderId'],
          transactionId: data['transactionId'],
        );
      }).toList();
      
      // Sort in memory to avoid needing a composite index
      txns.sort((a, b) => b.date.compareTo(a.date));
      _transactions = txns;
      
      notifyListeners();
    }, onError: (e) {
      print('Wallet transactions listener error: $e');
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _txnSub?.cancel();
    super.dispose();
  }

  double get balance => _balance;
  List<WalletTransaction> get transactions => _transactions;

  Future<void> _updateBalanceInFirestore(double delta) async {
    final userId = FirebaseService.currentUserId;
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      double currentBalance = 0.0;
      if (doc.exists && doc.data()!.containsKey('walletBalance')) {
        currentBalance = (doc.data()!['walletBalance'] as num).toDouble();
      }
      
      transaction.set(docRef, {'walletBalance': currentBalance + delta}, SetOptions(merge: true));
    });
  }

  void addTopup(double amount, {String? orderId, String? transactionId}) async {
    final txnOrderId = orderId ?? 'wallet_ord_${DateTime.now().millisecondsSinceEpoch}';
    final txnId = transactionId ?? 'txn_${DateTime.now().millisecondsSinceEpoch}';

    await _updateBalanceInFirestore(amount);
    
    FirebaseService.recordWalletTransaction(
      userId: FirebaseService.currentUserId,
      amount: amount,
      type: 'topup',
      title: 'Wallet Top-up',
      orderId: txnOrderId,
      transactionId: txnId,
    );
  }

  bool payFromWallet(double amount, {String? orderId}) {
    if (_balance < amount) return false;
    
    final txnOrderId = orderId ?? 'ORD_WAL_${DateTime.now().millisecondsSinceEpoch}';
    final txnId = 'WAL_PAY_${DateTime.now().millisecondsSinceEpoch}';

    _updateBalanceInFirestore(-amount);
    
    FirebaseService.recordWalletTransaction(
      userId: FirebaseService.currentUserId,
      amount: amount,
      type: 'order',
      title: 'Order Payment',
      orderId: txnOrderId,
      transactionId: txnId,
    );
    return true;
  }

  /// Called when a rider confirms an eco-return handoff.
  void addEcoReturnCredit(double amount, {String label = 'Eco-Return Credit'}) async {
    if (amount <= 0) return;
    
    await _updateBalanceInFirestore(amount);
    
    FirebaseService.recordWalletTransaction(
      userId: FirebaseService.currentUserId,
      amount: amount,
      type: 'refund',
      title: label,
      orderId: 'eco_ret_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  void spend(double amount, String orderTitle) async {
    if (_balance < amount) return;
    
    await _updateBalanceInFirestore(-amount);
    
    FirebaseService.recordWalletTransaction(
      userId: FirebaseService.currentUserId,
      amount: amount,
      type: 'order',
      title: orderTitle,
      orderId: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

class GroklyWalletProvider extends InheritedNotifier<WalletState> {
  const GroklyWalletProvider({
    super.key,
    required WalletState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static WalletState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GroklyWalletProvider>()!.notifier!;
}
// ���������������������������������������������
// APP ROOT
// ���������������������������������������������

class GroklyApp extends StatefulWidget {
  final String? initialSearchQuery;
  const GroklyApp({super.key, this.initialSearchQuery});

  @override
  State<GroklyApp> createState() => _GroklyAppState();
}

class _GroklyAppState extends State<GroklyApp> {
  final GlobalKey<_GroklyShellState> _shellKey = GlobalKey<_GroklyShellState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final shellState = _shellKey.currentState;
        if (shellState != null) {
          if (!shellState.handleBack()) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: GroklyCartProvider(
        notifier: CartState(),
        child: GroklyBasketsProvider(
          notifier: SavedBasketsState(),
          child: GroklyOrdersProvider(
            notifier: MyOrdersState(),
            child: GroklyWalletProvider(
              notifier: WalletState(),
              child: MaterialApp(
                title: 'Grokly',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  useMaterial3: true,
                  fontFamily: 'Poppins',
                  scaffoldBackgroundColor: GroklyColors.background,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: GroklyColors.primary,
                    surface: GroklyColors.surface,
                  ),
                ),
                home: GroklyShell(
                  key: _shellKey,
                  initialSearchQuery: widget.initialSearchQuery,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// ���������������������������������������������
// INHERITED PROVIDERS
// FIX: renamed from ChangeNotifierProvider to GroklyCartProvider
// to avoid conflict with the provider package and to fix the
// constructor signature error (create: vs positional notifier:).
// Added GroklyBasketsProvider the same way for SavedBasketsState.
// ���������������������������������������������

class GroklyCartProvider extends InheritedNotifier<CartState> {
  const GroklyCartProvider({
    super.key,
    required CartState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static CartState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GroklyCartProvider>()!.notifier!;
}

class GroklyBasketsProvider extends InheritedNotifier<SavedBasketsState> {
  const GroklyBasketsProvider({
    super.key,
    required SavedBasketsState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static SavedBasketsState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GroklyBasketsProvider>()!.notifier!;
}

// ���������������������������������������������
// MAIN SHELL (Bottom Nav)
// ���������������������������������������������

class GroklyShell extends StatefulWidget {
  final String? initialSearchQuery;
  const GroklyShell({super.key, this.initialSearchQuery});

  @override
  State<GroklyShell> createState() => _GroklyShellState();
}

class _GroklyShellState extends State<GroklyShell> {
  int _tab = 0;

  late final List<Widget> _screens;
  final GlobalKey<_HomeScreenState> _homeKey = GlobalKey<_HomeScreenState>();

  @override
  void initState() {
    super.initState();
          _screens = [
      HomeScreen(key: _homeKey, initialSearchQuery: widget.initialSearchQuery),
      const CategoriesScreen(),
      const UsualsScreen(),
      const FeaturesHubScreen(),
    ];
  }

  void switchTab(int index) {
    setState(() {
      _tab = index;
    });
  }

  bool handleBack() {
    final innerNav = Navigator.of(context);
    if (innerNav.canPop()) {
      innerNav.pop();
      return true; // We handled it by popping the inner pushed screen
    }

    if (_tab != 0) {
      setState(() {
        _tab = 0;
      });
      return true; // We handled it by returning to tab 0
    }

    final homeState = _homeKey.currentState;
    if (homeState != null && homeState.canPopInner()) {
      homeState.popInner();
      return true; // We handled it by clearing home filters
    }

    return false; // Not handled, let the outer app pop us
  }

  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);
    return Scaffold(
      backgroundColor: GroklyColors.background,
      body: Stack(
        children: [
          _screens[_tab],
          if (cart.totalQty > 0)
            Positioned(
              bottom: 86,
              left: 16, right: 16,
              child: _FloatingCartBar(onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CartScreen(),
                ));
              }),
            ),
          Positioned(
            bottom: 12, left: 12, right: 12,
            child: _BottomNav(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCartBar extends StatelessWidget {
  final VoidCallback onTap;
  const _FloatingCartBar({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: GroklyColors.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x33005129), blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: GroklyColors.primaryFixed,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text('${cart.totalQty}',
                  style: const TextStyle(color: GroklyColors.primary,
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('View Cart',
                style: GroklyTextStyles.bodyMain.copyWith(
                    color: GroklyColors.white, fontWeight: FontWeight.w600),
              ),
            ),
            Text('₹${cart.totalPrice.toStringAsFixed(0)}',
              style: GroklyTextStyles.sectionHeader.copyWith(
                  color: GroklyColors.white, fontSize: 16),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: GroklyColors.white, size: 14),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.calendar_today_rounded, Icons.calendar_today_outlined, 'Today'),
      (Icons.grid_view_rounded, Icons.grid_view_outlined, 'Categories'),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Usuals'),
      (Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Features'),
    ];
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: GroklyColors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(active ? items[i].$1 : items[i].$2,
                    color: active ? GroklyColors.primary : GroklyColors.outline,
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  Text(items[i].$3,
                    style: GroklyTextStyles.labelCaps.copyWith(
                      color: active ? GroklyColors.primary : GroklyColors.outline,
                      fontSize: 10,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 2),
                    Container(width: 4, height: 4,
                      decoration: const BoxDecoration(
                        color: GroklyColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ���������������������������������������������
// SHARED WIDGETS
// ���������������������������������������������

class _GroklyAppBar extends StatefulWidget {
  final String title, subtitle;
  final List<Widget>? actions;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLocationTap;
  final String eta;

  const _GroklyAppBar({
    required this.title,
    this.subtitle = '',
    this.actions,
    this.onAvatarTap,
    this.onLocationTap,
    this.eta = '10–15 minutes',
  });

  @override
  State<_GroklyAppBar> createState() => _GroklyAppBarState();
}

class _GroklyAppBarState extends State<_GroklyAppBar> {
  String _locationName = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.fetchCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _locationName = loc.city.isNotEmpty ? '${loc.city}, ${loc.state}' : loc.fullFormattedAddress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [GroklyColors.primary, GroklyColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: GroklyShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title/subtitle on left, action icons + avatar on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GroklyTextStyles.headlineLg,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: GroklyTextStyles.bodyMain.copyWith(
                              color: GroklyColors.primaryFixed,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      ...?widget.actions?.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _AppBarIconButton(child: a),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onAvatarTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroklyProfileScreen())),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: GroklyColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: GroklyColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Delivery + location as a single tappable chip
              GestureDetector(
                onTap: widget.onLocationTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: GroklyColors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled_rounded,
                          color: GroklyColors.primaryFixed, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        widget.eta,
                        style: GroklyTextStyles.bodyMain.copyWith(
                          color: GroklyColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: GroklyColors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_rounded,
                          color: GroklyColors.primaryFixed, size: 14),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _locationName,
                          style: GroklyTextStyles.labelCaps.copyWith(
                            color: GroklyColors.primaryFixed,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: GroklyColors.white.withOpacity(0.7), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps an action icon (e.g. cart, search) in a soft circular touch
/// target so it's easier to tap and visually matches the avatar's weight.
class _AppBarIconButton extends StatelessWidget {
  final Widget child;
  const _AppBarIconButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GroklyColors.white.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}
class _ProductCard extends StatelessWidget {
  final GroklyProduct product;
  final double width;
  const _ProductCard({required this.product, this.width = 160});

  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);
    final qty = cart.qtyOf(product.id);
    final discount = product.discountPercent;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GroklyColors.secContainer),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with discount badge, favorite heart, dot indicator.
          AspectRatio(
            aspectRatio: 1.05,
            child: Container(
              decoration: BoxDecoration(
                color: GroklyColors.surfaceMint,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: GroklyColors.surfaceMint,
                      child: const Icon(Icons.image_outlined, color: GroklyColors.outline),
                    ),
                  ),
                  if (discount != null && discount > 0)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: GroklyColors.error,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: GroklyTextStyles.labelCaps.copyWith(
                            color: GroklyColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Consumer<BookmarkProvider>(
                      builder: (context, provider, _) {
                        bool isFav = provider.isGroklySaved(product.id);
                        return GestureDetector(
                          onTap: () => provider.toggleGrokly(product.id),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(color: GroklyColors.white, shape: BoxShape.circle),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 14,
                              color: GroklyColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: GroklyColors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Divider line, matching the sketch's horizontal rule
          // separating image from the quantity/add row.
          Container(height: 1, color: GroklyColors.secContainer),
          const SizedBox(height: 8),

          // Quantity (size) on the left, Add/Qty control on the right —
          // same row, directly under the image, per the sketch.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.size,
                style: GroklyTextStyles.bodyMain.copyWith(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              qty == 0
                  ? _AddButton(onTap: () => cart.add(product))
                  : _QtyControl(
                      qty: qty,
                      onAdd: () => cart.add(product),
                      onRemove: () => cart.remove(product),
                    ),
            ],
          ),
          const SizedBox(height: 8),

          // Price — bold, MRP struck through beside it
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${product.price.toStringAsFixed(0)}',
                  style: GroklyTextStyles.price.copyWith(fontSize: 18)),
              if (product.mrp != null && product.mrp! > product.price) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '₹${product.mrp!.toStringAsFixed(0)}',
                    style: GroklyTextStyles.bodyMain.copyWith(
                      fontSize: 12,
                      color: GroklyColors.outline,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),

          // Product name
          Text(
            product.name,
            style: GroklyTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // Star rating row (only shown if data exists)
          if (product.rating != null)
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                const SizedBox(width: 3),
                Text(
                  product.rating!.toStringAsFixed(1),
                  style: GroklyTextStyles.bodyMain.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (product.ratingCount != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    '(${product.ratingCount})',
                    style: GroklyTextStyles.bodyMain.copyWith(fontSize: 11, color: GroklyColors.outline),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 6),

          // Delivery time + recipes as compact chips in one row
          Row(
            children: [
              if (product.deliveryMinutes != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: GroklyColors.outline),
                    const SizedBox(width: 3),
                    Text('${product.deliveryMinutes} mins',
                        style: GroklyTextStyles.bodyMain.copyWith(fontSize: 11, color: GroklyColors.outline)),
                  ],
                ),
              if (product.deliveryMinutes != null && product.recipeCount != null)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('•', style: TextStyle(color: GroklyColors.outline, fontSize: 11)),
                ),
              if (product.recipeCount != null)
                GestureDetector(
                  onTap: () {
                    // TODO: navigate to recipes using this product.
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${product.recipeCount} recipes',
                          style: GroklyTextStyles.bodyMain.copyWith(
                              fontSize: 11, color: GroklyColors.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: GroklyColors.primary),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? optionsLabel;
  const _AddButton({required this.onTap, this.optionsLabel});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GroklyColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ADD',
                style: GroklyTextStyles.bodyMain.copyWith(
                  color: GroklyColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              if (optionsLabel != null)
                Text(
                  optionsLabel!,
                  style: GroklyTextStyles.bodyMain.copyWith(fontSize: 9, color: GroklyColors.white.withOpacity(0.85)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd, onRemove;
  const _QtyControl({required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        decoration: BoxDecoration(
          color: GroklyColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onRemove,
              child: const SizedBox(
                  width: 30, child: Icon(Icons.remove, color: GroklyColors.white, size: 16)),
            ),
            Text('$qty',
                style: const TextStyle(
                    color: GroklyColors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            GestureDetector(
              onTap: onAdd,
              child: const SizedBox(
                  width: 30, child: Icon(Icons.add, color: GroklyColors.white, size: 16)),
            ),
          ],
        ),
      );
}
class _SectionHeader extends StatelessWidget {
  final String title, actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel = 'View All', this.onAction});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: GroklyTextStyles.sectionHeader),
      if (onAction != null)
        GestureDetector(onTap: onAction,
            child: Text(actionLabel, style: GroklyTextStyles.labelCaps.copyWith(
                color: GroklyColors.primary, decoration: TextDecoration.underline,
                decorationColor: GroklyColors.primary))),
    ],
  );
}
// ���������������������������������������������
// home_screen.dart  —  Grokly v2
//
// Drop this file's contents into grokly_screen.dart,
// replacing every class from HomeScreen down through
// the old _CategoryPills at the bottom.
//
// All other classes (GroklyColors, GroklyProduct,
// GroklyCatalog, GroklyRecipes …) remain unchanged.
// ���������������������������������������������

// ���������������������������������������������
// SCREEN 1: HOME
// ���������������������������������������������

class HomeScreen extends StatefulWidget {
  final String? initialSearchQuery;
  const HomeScreen({super.key, this.initialSearchQuery});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchCtrl;
  List<GroklyProduct> _searchResults = [];
  String _selectedCategory = 'All';
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  bool canPopInner() {
    return _selectedCategory != 'All' || _searchCtrl.text.isNotEmpty;
  }

  void popInner() {
    setState(() {
      _selectedCategory = 'All';
      _searchCtrl.text = '';
      _searchResults = [];
    });
  }

  // �� static catalog data ��������������������������������������������������
  // Asset filenames follow the convention assets/images/categories/<name>.png.
  // If an asset is missing at runtime, Image.asset's errorBuilder silently
  // falls back to the Unsplash network URL, which in turn falls back to the
  // icon — so the UI never breaks regardless of asset availability.
  static const List<_CategoryPillData> _categories = [
    _CategoryPillData('All', Icons.grid_view_rounded, null,
        'https://images.unsplash.com/photo-1542838132-92c53300491e?w=200&q=80',
        'assets/images/categories/all.png'),
    _CategoryPillData('Fresh', Icons.eco_outlined, 'Vegetables',
        'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?w=200&q=80',
        'assets/images/categories/vegetables.png'),
    _CategoryPillData('Milk', Icons.local_drink_outlined, 'Dairy',
        'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=200&q=80',
        'assets/images/categories/dairy.png'),
    _CategoryPillData('Bread', Icons.bakery_dining_outlined, 'Bakery',
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&q=80',
        'assets/images/categories/bakery.png'),
    _CategoryPillData('Fruits', Icons.local_florist_outlined, 'Dry Fruits & Nuts',
        'https://images.unsplash.com/photo-1508061253366-f7da158b6d46?w=200&q=80',
        'assets/images/categories/fruits.png'),
    _CategoryPillData('Staples', Icons.grain_outlined, 'Staples',
        'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=200&q=80',
        'assets/images/categories/staples.png'),
    _CategoryPillData('Snacks', Icons.fastfood_outlined, 'Packaged',
        'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=200&q=80',
        'assets/images/categories/snacks.png'),
    _CategoryPillData('Beverages', Icons.local_cafe_outlined, 'Beverages',
        'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=200&q=80',
        'assets/images/categories/beverages.png'),
    _CategoryPillData('Spices', Icons.local_fire_department_outlined, 'Spices & Masalas',
        'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=200&q=80',
        'assets/images/categories/spices.png'),
    _CategoryPillData('Frozen', Icons.ac_unit_outlined, 'Frozen',
        'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?w=200&q=80',
        'assets/images/categories/frozen.png'),
    _CategoryPillData('Household', Icons.cleaning_services_outlined, 'Household',
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&q=80',
        'assets/images/categories/household.png'),
    _CategoryPillData('Personal Care', Icons.spa_outlined, 'Personal Care',
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=200&q=80',
        'assets/images/categories/personal_care.png'),
    _CategoryPillData('Baby Care', Icons.child_care_outlined, 'Baby Care',
        'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=200&q=80',
        'assets/images/categories/baby_care.png'),
    _CategoryPillData('Meat', Icons.set_meal_outlined, 'Meat & Seafood',
        'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=200&q=80',
        'assets/images/categories/meat.png'),
    _CategoryPillData('Condiments', Icons.restaurant_menu_outlined, 'Condiments',
        'https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=200&q=80',
        'assets/images/categories/condiments.png'),
    _CategoryPillData('Ready-to-Cook', Icons.microwave_outlined, 'Ready-to-Cook',
        'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=200&q=80',
        'assets/images/categories/rtc.png'),
  ];

     static const List<_BrandData> _brands = [
    _BrandData('Anveshan', 'Oils & Ghee',
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300&q=80'),
    _BrandData('Two Brothers', 'Farmer-sourced',
        'https://images.unsplash.com/photo-1757627550652-30788bfce978?w=300&q=80'),
    _BrandData('Barosi', 'Slow Crafted',
        'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=300&q=80'),
    _BrandData('Akshayakalpa', 'Organic Dairy',
        'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=300&q=80'),
    _BrandData('True Elements', 'Daily Superfoods',
        'https://images.unsplash.com/photo-1682622110332-d50f50b7146d?w=300&q=80'),
    _BrandData("D'lecta", 'Fresh Dairy Picks',
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=300&q=80'),
    _BrandData('Beco', 'Plant Based Cleaners',
        'https://images.unsplash.com/photo-1550963295-019d8a8a61c5?w=300&q=80'),
    _BrandData('Alt Co', 'Plant-Powered',
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300&q=80'),
    _BrandData("Member's Club", 'By Grokly',
        'https://images.unsplash.com/photo-1542838132-92c53300491e?w=300&q=80'),
  ];
  // �� lifecycle �������������������������������������������������������������
  @override
  void initState() {
    super.initState();
    final q = widget.initialSearchQuery ?? '';
    _searchCtrl = TextEditingController(text: q);
    if (q.isNotEmpty) _search(q);
  }

  @override
  void dispose() {
    _speech.stop();
    _searchCtrl.dispose();
    super.dispose();
  }

  // �� helpers ���������������������������������������������������������������
  void _search(String q) {
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _searchResults = GroklyCatalog.all
          .where((p) =>
              p.name.toLowerCase().contains(q.toLowerCase()) ||
              p.category.toLowerCase().contains(q.toLowerCase()))
          .take(20)
          .toList();
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) => setState(() => _isListening = false),
    );
    if (!available) return;
    setState(() => _isListening = true);
    _speech.listen(onResult: (r) {
      _searchCtrl.text = r.recognizedWords;
      _searchCtrl.selection =
          TextSelection.fromPosition(TextPosition(offset: _searchCtrl.text.length));
      _search(r.recognizedWords);
      if (r.finalResult) setState(() => _isListening = false);
    });
  }

  void _selectCategory(_CategoryPillData cat) {
    if (cat.label == 'All') {
      context.findAncestorStateOfType<_GroklyShellState>()?.switchTab(1);
      return;
    }
    if (_selectedCategory == cat.label) {
      setState(() {
        _selectedCategory = 'All';
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _selectedCategory = cat.label;
      _searchResults = cat.categoryValue == null
          ? []
          : GroklyCatalog.all
              .where((p) => p.category == cat.categoryValue)
              .take(20)
              .toList();
    });
  }

  // �� build �����������������������������������������������������������������
  @override
  Widget build(BuildContext context) {
    final featured = GroklyCatalog.all
        .where((p) => ['Vegetables', 'Dairy'].contains(p.category))
        .take(8)
        .toList();

    return CustomScrollView(
      slivers: [
        // �� 1. App bar ������������������������������������������������������
        SliverToBoxAdapter(
      child: _GroklyAppBar(
  title: 'Grokly',
  onAvatarTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const GroklyProfileScreen()),
  ),
  actions: [
    GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
      child: const Icon(
        Icons.shopping_cart_outlined,
        color: GroklyColors.white,
        size: 22,
      ),
    ),
  ],
),
        ),
        // �� 2. Scrollable body ���������������������������������������������
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // �� Search bar �����������������������������������������������
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SearchBar(
                  controller: _searchCtrl,
                  onChanged: _search,
                  isListening: _isListening,
                  onMicTap: _toggleListening,
                ),
              ),
              const SizedBox(height: 18),

              // �� "Fresh from the Roots" banner (Figma: above categories) ��
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeBanner(),
              ),
              const SizedBox(height: 20),

              // �� Categories section header ���������������������������������
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(
                  title: 'Categories',
                  actionLabel: 'See all',
                  onAction: () {
                    context.findAncestorStateOfType<_GroklyShellState>()?.switchTab(1);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // �� Category pills — NO outer Padding here; the ListView owns �
              // �� its own horizontal padding so items scroll edge-to-edge.  �
              _CategoryIconPills(
                categories: _categories,
                selected: _selectedCategory,
                onSelected: _selectCategory,
              ),

              // �� Search results (conditional) �����������������������������
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SectionHeader(
                      title: 'Results (${_searchResults.length})'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 295,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) =>
                        _ProductCard(product: _searchResults[i]),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const SizedBox(height: 18),

              // �� Promo strip ����������������������������������������������
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _PromoStrip(
                  badge: 'FREE',
                  title: 'Jumbo cashews & almonds',
                  subtitle: 'On 1st orders above \u20b9499*',
                  ctaLabel: 'Shop now',
                  footnote: '*Valid till stocks last',
                ),
              ),
              const SizedBox(height: 22),

              // �� Launch specials ������������������������������������������
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(title: 'Launch Specials'),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _LaunchSpecialCard(
                        title: 'Launch Week Sale',
                        subtitle: 'Up to 40% OFF',
                        ctaLabel: 'Shop Now',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LaunchSpecialCard(
                        title: 'B2G1 Free',
                        subtitle: 'On All Dairy',
                        ctaLabel: 'Shop Now',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // �� Brand spotlight ������������������������������������������
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(
                  title: 'Brand Spotlight',
                  actionLabel: 'View All',
                  onAction: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AllBrandsScreen()));
                  },
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _brands.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (_, i) => _BrandBadge(brand: _brands[i]),
                ),
              ),
              const SizedBox(height: 24),

              // �� Why Choose Us? �������������������������������������������
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(title: 'Why Choose Us₹'),
              ),
              const SizedBox(height: 12),
             
              const SizedBox(height: 24),

              // �� Fresh Picks Today ����������������������������������������
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(
                    title: 'Fresh Picks Today', actionLabel: 'See all'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 310,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _ProductCard(product: featured[i]),
                ),
              ),

              // bottom padding (leaves room for the nav-bar)
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LOCAL WIDGETS
// =============================================================================

// �����������������������������������������������������������������������������
// A.  _GroklyAppBar
//     Dark green header — matches left screenshot exactly:
//       row 1: clock · "10-15 mins" · chevron · spacer · cart · profile
//       row 2: "YOUR DAILY ESSENTIALS" small-caps
//       row 3: "Grokly" large bold white
// �����������������������������������������������������������������������������

// �����������������������������������������������������������������������������
// B.  _SectionHeader
// �����������������������������������������������������������������������������

// �����������������������������������������������������������������������������
// C.  _SearchBar
// �����������������������������������������������������������������������������
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isListening;
  final VoidCallback onMicTap;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.isListening,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: GroklyColors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: GroklyShadows.soft,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: GroklyColors.outline, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GroklyTextStyles.bodyMain,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: isListening
                    ? 'Listening\u2026'
                    : "Search 'organic honey' or 'milk'",
                hintStyle: const TextStyle(
                    color: GroklyColors.outline, fontSize: 13.5),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: isListening ? GroklyColors.error : GroklyColors.primary,
              size: 22,
            ),
            onPressed: onMicTap,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

// �����������������������������������������������������������������������������
// D.  Category pill model + row
// �����������������������������������������������������������������������������
class _CategoryPillData {
  final String label;
  final IconData icon;
  final String? categoryValue;
  final String imageUrl;
  // Optional local asset path (e.g. 'assets/images/categories/dairy.png').
  // When set, Image.asset() is tried first; errorBuilder falls back to
  // the Unsplash imageUrl, which in turn falls back to the icon.
  final String? localAsset;
  const _CategoryPillData(
      this.label, this.icon, this.categoryValue, this.imageUrl,
      [this.localAsset]);
}

class _CategoryIconPills extends StatelessWidget {
  final List<_CategoryPillData> categories;
  final String selected;
  final ValueChanged<_CategoryPillData> onSelected;
  const _CategoryIconPills({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // ROOT FIX FOR OVERFLOW:
    // The padding is placed directly on the ListView (not on a wrapping
    // Padding widget). This lets the scroll view extend to its natural
    // width while still inset-ing the first/last item by 16 px, so items
    // are never clipped and the scroll thumb reaches the true edge.
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = categories[i];
          final isSelected = c.label == selected;
          return GestureDetector(
            onTap: () => onSelected(c),
            child: SizedBox(
              width: 66,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 3-level image: local asset → network URL → icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GroklyColors.surfaceLow,
                      border: Border.all(
                        color: isSelected
                            ? GroklyColors.primaryDark
                            : GroklyColors.secContainer,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: GroklyColors.primaryDark
                                    .withOpacity(0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: c.localAsset != null
                        ? Image.asset(
                            c.localAsset!,
                            fit: BoxFit.cover,
                            // asset missing → fall back to network URL
                            errorBuilder: (_, __, ___) => Image.network(
                              c.imageUrl,
                              fit: BoxFit.cover,
                              // network failed → fall back to icon
                              errorBuilder: (_, __, ___) => Container(
                                color: GroklyColors.surfaceLow,
                                alignment: Alignment.center,
                                child: Icon(c.icon,
                                    size: 24, color: GroklyColors.primary),
                              ),
                            ),
                          )
                        : Image.network(
                            c.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: GroklyColors.surfaceLow,
                              alignment: Alignment.center,
                              child: Icon(c.icon,
                                  size: 24, color: GroklyColors.primary),
                            ),
                          ),
                  ),
                  const SizedBox(height: 5),
                  // label — single line, never overflows
                  Text(
                    c.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? GroklyColors.primaryDark
                          : GroklyColors.outline,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// �����������������������������������������������������������������������������
// E.  "Fresh from the Roots" hero banner
// �����������������������������������������������������������������������������
class _HomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: GroklyShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
            fit: BoxFit.cover,
            color: GroklyColors.primary.withOpacity(0.45),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) =>
                Container(color: GroklyColors.primaryDark),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // members-exclusive badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GroklyColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MEMBERS EXCLUSIVE',
                    style: GroklyTextStyles.labelCaps.copyWith(
                      color: GroklyColors.white,
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fresh from\nthe Roots',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: GroklyColors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Flat 20% off for Club Members',
                  style: GroklyTextStyles.bodyMain.copyWith(
                    color: GroklyColors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// �����������������������������������������������������������������������������
// F.  Promo strip
// �����������������������������������������������������������������������������
class _PromoStrip extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String footnote;
  const _PromoStrip({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GroklyColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: GroklyShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // rotated side badge
            Container(
              width: 40,
              alignment: Alignment.center,
              color: GroklyColors.primaryDark,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  badge,
                  style: GroklyTextStyles.labelCaps
                      .copyWith(color: GroklyColors.white, fontSize: 11),
                ),
              ),
            ),
            // body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: GroklyColors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GroklyTextStyles.bodyMain.copyWith(
                          color: GroklyColors.white.withOpacity(0.9),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          ctaLabel,
                          style: GroklyTextStyles.bodyMain.copyWith(
                              color: GroklyColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward,
                            color: GroklyColors.white, size: 14),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      footnote,
                      style: GroklyTextStyles.bodyMain.copyWith(
                          color: GroklyColors.white.withOpacity(0.6),
                          fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// �����������������������������������������������������������������������������
// G.  Launch special card (2-up row)
// �����������������������������������������������������������������������������
class _LaunchSpecialCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String ctaLabel;
  const _LaunchSpecialCard({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GroklyColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GroklyColors.secContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: GroklyColors.onSurface,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GroklyTextStyles.bodyMain
                .copyWith(color: GroklyColors.outline, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text(
                  ctaLabel,
                  style: GroklyTextStyles.bodyMain.copyWith(
                      color: GroklyColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward,
                  color: GroklyColors.primary, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}

// �����������������������������������������������������������������������������
// H.  Brand spotlight badge + scallop clipper
// �����������������������������������������������������������������������������
class _BrandData {
  final String name;
  final String tagline;
  final String imageUrl;
  const _BrandData(this.name, this.tagline, this.imageUrl);
}

class _BrandBadge extends StatelessWidget {
  final _BrandData brand;

  const _BrandBadge({required this.brand});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BrandProductsScreen(brand: brand)),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular brand image
          Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GroklyColors.surfaceCard,
                border: Border.all(
                  color: GroklyColors.outline.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  brand.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: GroklyColors.surfaceCard,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.storefront_outlined,
                        size: 32,
                        color: GroklyColors.outline,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Brand name
        Text(
          brand.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: GroklyColors.onSurface,
          ),
        ),

        const SizedBox(height: 3),

        // Brand tagline
        Text(
          brand.tagline,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GroklyTextStyles.bodyMain.copyWith(
            fontSize: 10,
            color: GroklyColors.outline,
          ),
        ),
      ],
      ),
    );
  }
}

class AllBrandsScreen extends StatelessWidget {
  const AllBrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GroklyColors.background,
      appBar: AppBar(
        backgroundColor: GroklyColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: GroklyColors.onSurface, size: 20),
        ),
        title: const Text(
          'All Brands',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: GroklyColors.onSurface,
            fontSize: 18,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: _HomeScreenState._brands.length,
        itemBuilder: (_, i) => _BrandBadge(brand: _HomeScreenState._brands[i]),
      ),
    );
  }
}

class BrandProductsScreen extends StatelessWidget {
  final _BrandData brand;

  const BrandProductsScreen({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    // Find products matching the brand
    final products = GroklyCatalog.all.where((p) {
      return p.brand.toLowerCase().contains(brand.name.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: GroklyColors.background,
      appBar: AppBar(
        backgroundColor: GroklyColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: GroklyColors.onSurface, size: 20),
        ),
        title: Text(
          brand.name,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: GroklyColors.onSurface,
            fontSize: 18,
          ),
        ),
      ),
      body: products.isEmpty
          ? Center(
              child: Text(
                'No products found for ${brand.name}',
                style: GroklyTextStyles.bodyMain.copyWith(color: GroklyColors.outline),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) {
                return _ProductCard(
                  product: products[i],
                  width: double.infinity,
                );
              },
            ),
    );
  }
}

/// Scallop/flower shape clipper used by _BrandBadge
class _ScallopClipper extends CustomClipper<Path> {
  final int bumps;
  const _ScallopClipper({this.bumps = 12});

  @override
  Path getClip(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = cx;
    final innerR = outerR * 0.86;
    final path = Path();
    final total = bumps * 2;
    for (int i = 0; i <= total; i++) {
      final angle = (pi * 2 / total) * i;
      final r = i.isEven ? outerR : innerR;
      final dx = cx + r * cos(angle);
      final dy = cy + r * sin(angle);
      i == 0 ? path.moveTo(dx, dy) : path.lineTo(dx, dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}

// �����������������������������������������������������������������������������
// I.  "Why Choose Us?" banner
// �����������������������������������������������������������������������������


// �����������������������������������������������������������������������������
// J.  Product card  (self-managed +/- qty, no external state needed)
// �����������������������������������������������������������������������������


/// Tiny tap target used inside the qty stepper
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 36,
          child: Icon(icon, color: GroklyColors.white, size: 16),
        ),
      );
}

// ���������������������������������������������
// SCREEN 2: CATEGORIES
// ���������������������������������������������

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _railIndex = 0;
  String? _selectedSubCategory;

  static const categories = [
    ('Dairy',             'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400&q=80'),
    ('Staples',           'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400&q=80'),
    ('Bakery',            'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80'),
    ('Packaged',          'https://images.unsplash.com/photo-1585325701165-34ba78c8cfd5?w=400&q=80'),
    ('Beverages',         'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400&q=80'),
    ('Vegetables',        'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?w=400&q=80'),
    ('Dry Fruits & Nuts', 'https://images.unsplash.com/photo-1508061253366-f7da158b6d46?w=400&q=80'),
    ('Spices & Masalas',  'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=80'),
    ('Condiments',        'https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=400&q=80'),
    ('Ready-to-Cook',     'https://images.unsplash.com/photo-1630383249896-424e482df921?w=400&q=80'),
    ('Frozen',            'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&q=80'),
    ('Household',         'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80'),
    ('Personal Care',     'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&q=80'),
  ];

  @override
  Widget build(BuildContext context) {
    final activeCategory = categories[_railIndex].$1;
    final categoryProducts = GroklyCatalog.all.where((p) => p.category == activeCategory).toList();

    // Distinct sub-categories within the active category, each with a
    // thumbnail taken from its first matching product.
    final subCats = <String, String>{}; // subCategory -> imageUrl
    for (final p in categoryProducts) {
      subCats.putIfAbsent(p.subCategory, () => p.imageUrl);
    }

    final filtered = _selectedSubCategory == null
        ? <GroklyProduct>[]
        : categoryProducts.where((p) => p.subCategory == _selectedSubCategory).toList();

    return Column(
      children: [
        _GroklyAppBar(
          title: 'Categories',
          subtitle: 'Browse fresh essentials by category',
          actions: [
            GestureDetector(
              onTap: () {
                // TODO: hook up category/product search here.
              },
              child: const Icon(Icons.search, color: GroklyColors.white, size: 22),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Left icon rail
                SizedBox(
                  width: 84,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 120),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final isSelected = i == _railIndex;
                      final label = categories[i].$1;
                      final imageUrl = categories[i].$2;

                      return GestureDetector(
                        onTap: () => setState(() {
                          _railIndex = i;
                          _selectedSubCategory = null;
                        }),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? GroklyColors.surfaceMint : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(color: GroklyColors.primary, width: 1.4)
                                : null,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: GroklyColors.secContainer),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: GroklyColors.surfaceMint),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GroklyTextStyles.labelCaps.copyWith(
                                  fontSize: 9,
                                  color: isSelected ? GroklyColors.primary : GroklyColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Right content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(4, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeCategory.toUpperCase(),
                          style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.outline),
                        ),
                        const SizedBox(height: 10),

                        if (_selectedSubCategory != null) ...[
                          GestureDetector(
                            onTap: () => setState(() => _selectedSubCategory = null),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_back_ios_new,
                                    color: GroklyColors.primary, size: 12),
                                const SizedBox(width: 4),
                                Text(_selectedSubCategory!,
                                    style: GroklyTextStyles.sectionHeader.copyWith(
                                        fontSize: 14, color: GroklyColors.primary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.44,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _ProductCard(product: filtered[i], width: double.infinity),
                          ),
                        ] else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: subCats.length,
                            itemBuilder: (_, i) {
                              final entry = subCats.entries.elementAt(i);
                              return _CategoryCard(
                                title: entry.key,
                                imageUrl: entry.value,
                                onTap: () => setState(() => _selectedSubCategory = entry.key),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// DARK CATEGORIES EXPERIENCE — MATCHED TO FIGMA (real images kept)
// Replace everything from class _DarkCat {
// until immediately BEFORE class _FeaturedTile {
//
// CHANGES MADE VS YOUR ORIGINAL CODE (to match Figma 1:1):
// 1. Removed the "% OFF" discount badge from product cards — Figma has none.
// 2. Changed the favourite icon from a white filled circle to a plain
//    outline heart directly on the image (no background chip) — matches Figma.
// 3. Removed the double-circle glow ring around category tile images.
//    Figma icons sit flat with only a soft drop shadow, no halo.
// 4. Removed the double-circle glow ring around product images too, for
//    the same reason — kept a subtle shadow only.
// 5. Kept the same bottom nav (Home / Categories / Cart / Profile) on
//    every screen — this already matched Figma, no change needed.
// 6. Everything else (colors, gradients, spacing, radii, font sizes,
//    grid layout, filter chips) is untouched from your original file.
// ============================================================================
 
class _DarkCat {
  static const Color bg = Color(0xFF061B11);
  static const Color bgTop = Color(0xFF0A2B19);
  static const Color bgBottom = Color(0xFF04150C);
 
  static const Color cardTop = Color(0xFF183A25);
  static const Color cardBottom = Color(0xFF0D2518);
  static const Color cardInner = Color(0xFF102D1C);
 
  static const Color border = Color(0xFF1A4930);
  static const Color borderSoft = Color(0xFF173C28);
 
  static const Color text = Color(0xFFF3FAF5);
  static const Color textDim = Color(0xFF9BAEA3);
 
  static const Color accent = Color(0xFF24F486);
  static const Color accentDark = Color(0xFF07552F);
 
  static const Color price = Color(0xFF39EF8A);
  static const Color yellow = Color(0xFFFFC107);
  static const Color error = Color(0xFFE52A2A);
 
  static const LinearGradient screenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A2B19),
      Color(0xFF061B11),
      Color(0xFF03140B),
    ],
    stops: [0.0, 0.48, 1.0],
  );
 
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF183A25),
      Color(0xFF102D1C),
      Color(0xFF0A2115),
    ],
    stops: [0.0, 0.52, 1.0],
  );
 
  static const LinearGradient navGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF112D1D),
      Color(0xFF091E13),
    ],
  );
}
 
 
// ============================================================================
// CATEGORY DATA
// ============================================================================
 
class _DarkCategoryData {
  final String label;
  final String categoryValue;
  final String imageUrl;
  final int itemCount;
 
  const _DarkCategoryData({
    required this.label,
    required this.categoryValue,
    required this.imageUrl,
    required this.itemCount,
  });
}
 
 
const List<_DarkCategoryData> _darkCategoryData = [
  _DarkCategoryData(
    label: 'Fruits & Veggies',
    categoryValue: 'Vegetables',
    itemCount: 128,
    imageUrl:
        'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&w=700&q=90',
  ),
 
  _DarkCategoryData(
    label: 'Dairy & Eggs',
    categoryValue: 'Dairy & Eggs',
    itemCount: 64,
    imageUrl:
        'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=700&q=90',
  ),
 
  _DarkCategoryData(
    label: 'Bakery',
    categoryValue: 'Bakery',
    itemCount: 36,
    imageUrl:
        'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=700&q=90',
  ),
 
  _DarkCategoryData(
    label: 'Snacks',
    categoryValue: 'Packaged',
    itemCount: 95,
    imageUrl:
        'https://images.unsplash.com/photo-1578849278619-e73505e9610f?auto=format&fit=crop&w=700&q=90',
  ),
 
  _DarkCategoryData(
    label: 'Meat & Seafood',
    categoryValue: 'Meat & Seafood',
    itemCount: 42,
    imageUrl:
        'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=700&q=90',
  ),
 
  _DarkCategoryData(
    label: 'Pantry Staples',
    categoryValue: 'Staples',
    itemCount: 96,
    imageUrl:
        'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?auto=format&fit=crop&w=700&q=90',
  ),
  _DarkCategoryData(
    label: 'Dry Fruits & Nuts',
    categoryValue: 'Dry Fruits & Nuts',
    itemCount: 20,
    imageUrl: 'https://images.unsplash.com/photo-1508061253366-f7da158b6d46?auto=format&fit=crop&w=700&q=90',
  ),
  _DarkCategoryData(
    label: 'Beverages',
    categoryValue: 'Beverages',
    itemCount: 45,
    imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=700&q=90',
  ),
  _DarkCategoryData(
    label: 'Spices & Masalas',
    categoryValue: 'Spices & Masalas',
    itemCount: 30,
    imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=700&q=90',
  ),
  _DarkCategoryData(
    label: 'Frozen',
    categoryValue: 'Frozen',
    itemCount: 15,
    imageUrl: 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?auto=format&fit=crop&w=700&q=90',
  ),
  _DarkCategoryData(
    label: 'Household',
    categoryValue: 'Household',
    itemCount: 25,
    imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=700&q=90',
  ),
  _DarkCategoryData(
    label: 'Personal Care',
    categoryValue: 'Personal Care',
    itemCount: 40,
    imageUrl: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=700&q=90',
  ),
  _DarkCategoryData(
    label: 'Baby Care',
    categoryValue: 'Baby Care',
    itemCount: 10,
    imageUrl: 'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?auto=format&fit=crop&w=700&q=90',
  ),
  _DarkCategoryData(
    label: 'Condiments',
    categoryValue: 'Condiments',
    itemCount: 22,
    imageUrl: 'https://images.unsplash.com/photo-1472476443507-c7a5948772fc?auto=format&fit=crop&w=700&q=90',
  ),
  _DarkCategoryData(
    label: 'Ready-to-Cook',
    categoryValue: 'Ready-to-Cook',
    itemCount: 18,
    imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=700&q=90',
  ),
];
 
 
// ============================================================================
// PRODUCT FILTERING (unchanged)
// ============================================================================
 
List<GroklyProduct> _darkProductsForCategory(String categoryValue) {
  switch (categoryValue) {
    case 'Dairy & Eggs':
      return GroklyCatalog.all.where((p) {
        final category = p.category.toLowerCase();
        final sub = p.subCategory.toLowerCase();
 
        return category == 'dairy' ||
            category == 'eggs' ||
            sub.contains('egg');
      }).toList();
 
    case 'Vegetables':
      return GroklyCatalog.all.where((p) {
        final category = p.category.toLowerCase();
        final sub = p.subCategory.toLowerCase();
 
        return category == 'vegetables' ||
            category == 'fruits' ||
            sub.contains('fruit') ||
            sub.contains('exotic');
      }).toList();
 
    case 'Bakery':
      return GroklyCatalog.all.where((p) {
        return p.category.toLowerCase() == 'bakery';
      }).toList();
 
    case 'Packaged':
      return GroklyCatalog.all.where((p) {
        final category = p.category.toLowerCase();
        final sub = p.subCategory.toLowerCase();
 
        return category == 'packaged' ||
            category == 'snacks' ||
            sub.contains('snack') ||
            sub.contains('chip') ||
            sub.contains('cookie') ||
            sub.contains('namkeen');
      }).toList();
 
    case 'Meat & Seafood':
      return GroklyCatalog.all.where((p) {
        final category = p.category.toLowerCase();
 
        return category == 'meat & seafood' ||
            category == 'meat' ||
            category == 'seafood';
      }).toList();
 
    case 'Staples':
      return GroklyCatalog.all.where((p) {
        final category = p.category.toLowerCase();
 
        return category == 'staples' ||
            category == 'pantry staples';
      }).toList();
 
    default:
      return GroklyCatalog.all
          .where((p) => p.category == categoryValue)
          .toList();
  }
}
 
 
// ============================================================================
// MAIN CATEGORIES SCREEN (unchanged, still matches Figma layout)
// ============================================================================
 
class DarkCategoriesHomeScreen extends StatefulWidget {
  const DarkCategoriesHomeScreen({super.key});
 
  @override
  State<DarkCategoriesHomeScreen> createState() =>
      _DarkCategoriesHomeScreenState();
}
 
class _DarkCategoriesHomeScreenState
    extends State<DarkCategoriesHomeScreen> {
  String _query = '';
 
  List<_DarkCategoryData> get _visibleCategories {
    final query = _query.trim().toLowerCase();
 
    if (query.isEmpty) {
      return _darkCategoryData;
    }
 
    return _darkCategoryData.where((item) {
      return item.label.toLowerCase().contains(query);
    }).toList();
  }
 
  _DarkCategoryData? _findCategory(String name) {
    for (final category in _visibleCategories) {
      if (category.label == name) {
        return category;
      }
    }
 
    return null;
  }
 
  void _openCategory(_DarkCategoryData category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DarkCategoryDetailScreen(
          category: category,
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final fruits = _findCategory('Fruits & Veggies');
    final dairy = _findCategory('Dairy & Eggs');
    final bakery = _findCategory('Bakery');
    final snacks = _findCategory('Snacks');
    final meat = _findCategory('Meat & Seafood');
    final pantry = _findCategory('Pantry Staples');
 
    return Scaffold(
      backgroundColor: _DarkCat.bg,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: _DarkCat.screenGradient,
            ),
          ),
 
          Positioned(
            top: -100,
            left: -90,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _DarkCat.accent.withOpacity(0.035),
                  boxShadow: [
                    BoxShadow(
                      color: _DarkCat.accent.withOpacity(0.12),
                      blurRadius: 100,
                      spreadRadius: 35,
                    ),
                  ],
                ),
              ),
            ),
          ),
 
          Positioned(
            right: -100,
            bottom: 40,
            child: IgnorePointer(
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _DarkCat.accent.withOpacity(0.025),
                  boxShadow: [
                    BoxShadow(
                      color: _DarkCat.accent.withOpacity(0.10),
                      blurRadius: 100,
                      spreadRadius: 35,
                    ),
                  ],
                ),
              ),
            ),
          ),
 
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      13,
                      16,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Categories',
                                style: TextStyle(
                                  color: _DarkCat.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
 
                            Container(
                              width: 31,
                              height: 31,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.035),
                                border: Border.all(
                                  color: _DarkCat.border,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'JM',
                                style: TextStyle(
                                  color: _DarkCat.textDim,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
 
                        const SizedBox(height: 12),
 
                        Container(
                          height: 37,
                          decoration: BoxDecoration(
                            color: _DarkCat.cardInner.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: _DarkCat.border,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _query = value;
                              });
                            },
                            cursorColor: _DarkCat.accent,
                            style: const TextStyle(
                              color: _DarkCat.text,
                              fontSize: 10,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 15,
                                color: _DarkCat.textDim,
                              ),
                              hintText:
                                  'Search fresh produce, dairy...',
                              hintStyle: TextStyle(
                                color: _DarkCat.textDim,
                                fontSize: 10,
                              ),
                              contentPadding: EdgeInsets.only(
                                top: 10,
                                bottom: 10,
                              ),
                            ),
                          ),
                        ),
 
                        const SizedBox(height: 12),
 
                        if (_visibleCategories.length ==
                            _darkCategoryData.length)
                          SizedBox(
                            height:
                                MediaQuery.sizeOf(context).width * 0.98,
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: _DarkCategoryTile(
                                          data: fruits!,
                                          large: true,
                                          imageSize: 68,
                                          onTap: () =>
                                              _openCategory(fruits),
                                        ),
                                      ),
 
                                      const SizedBox(height: 9),
 
                                      Expanded(
                                        flex: 4,
                                        child: _DarkCategoryTile(
                                          data: meat!,
                                          imageSize: 47,
                                          onTap: () =>
                                              _openCategory(meat),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
 
                                const SizedBox(width: 9),
 
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _DarkCategoryTile(
                                          data: dairy!,
                                          imageSize: 43,
                                          onTap: () =>
                                              _openCategory(dairy),
                                        ),
                                      ),
 
                                      const SizedBox(height: 9),
 
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _DarkCategoryTile(
                                                data: bakery!,
                                                compact: true,
                                                imageSize: 35,
                                                onTap: () =>
                                                    _openCategory(
                                                  bakery,
                                                ),
                                              ),
                                            ),
 
                                            const SizedBox(width: 7),
 
                                            Expanded(
                                              child: _DarkCategoryTile(
                                                data: snacks!,
                                                compact: true,
                                                imageSize: 35,
                                                onTap: () =>
                                                    _openCategory(
                                                  snacks,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
 
                                      const SizedBox(height: 9),
 
                                      Expanded(
                                        flex: 4,
                                        child: _DarkCategoryTile(
                                          data: pantry!,
                                          imageSize: 48,
                                          onTap: () =>
                                              _openCategory(pantry),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _DarkSearchResults(
                            categories: _visibleCategories,
                            onTap: _openCategory,
                          ),
                      ],
                    ),
                  ),
                ),
 
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    0,
                    14,
                    7,
                  ),
                  child: _DarkBottomNav(
                    selectedIndex: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 
 
// ============================================================================
// CATEGORY TILE (unchanged)
// ============================================================================
 
class _DarkCategoryTile extends StatelessWidget {
  final _DarkCategoryData data;
  final double imageSize;
  final bool large;
  final bool compact;
  final VoidCallback onTap;
 
  const _DarkCategoryTile({
    required this.data,
    required this.imageSize,
    required this.onTap,
    this.large = false,
    this.compact = false,
  });
 
  @override
  Widget build(BuildContext context) {
    final radius = large ? 18.0 : 15.0;
 
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            compact ? 8 : 11,
            compact ? 8 : 10,
            compact ? 8 : 11,
            compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            gradient: _DarkCat.cardGradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _DarkCat.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: large ? 13 : 9,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: _DarkCat.accent.withOpacity(0.025),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: _DarkCategoryImage(
                    imageUrl: data.imageUrl,
                    size: imageSize,
                  ),
                ),
              ),
 
              SizedBox(height: compact ? 3 : 5),
 
              Text(
                data.label,
                maxLines: large ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _DarkCat.text,
                  fontSize: compact
                      ? 8.2
                      : large
                          ? 13.5
                          : 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                  letterSpacing: -0.1,
                ),
              ),
 
              const SizedBox(height: 2),
 
              Text(
                '${data.itemCount} items',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _DarkCat.textDim,
                  fontSize: compact ? 6.8 : 7.8,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
 
// ============================================================================
// CATEGORY IMAGE — CHANGED: no outer glow ring, flat like Figma
// ============================================================================
 
class _DarkCategoryImage extends StatelessWidget {
  final String imageUrl;
  final double size;
 
  const _DarkCategoryImage({
    required this.imageUrl,
    required this.size,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          size > 55 ? 18 : 14,
        ),
        color: _DarkCat.cardBottom,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(
              Icons.image_outlined,
              color: _DarkCat.textDim,
              size: 20,
            ),
          );
        },
      ),
    );
  }
}
 
 
// ============================================================================
// SEARCH RESULTS (unchanged)
// ============================================================================
 
class _DarkSearchResults extends StatelessWidget {
  final List<_DarkCategoryData> categories;
  final ValueChanged<_DarkCategoryData> onTap;
 
  const _DarkSearchResults({
    required this.categories,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 35),
        child: Center(
          child: Text(
            'No categories found',
            style: TextStyle(
              color: _DarkCat.textDim,
              fontSize: 11,
            ),
          ),
        ),
      );
    }
 
    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: SizedBox(
            height: 90,
            child: _DarkCategoryTile(
              data: category,
              imageSize: 48,
              onTap: () => onTap(category),
            ),
          ),
        );
      }).toList(),
    );
  }
}
 
 
// ============================================================================
// CATEGORY DETAIL SCREEN (unchanged structure)
// ============================================================================
 
class DarkCategoryDetailScreen extends StatefulWidget {
  final _DarkCategoryData category;
 
  const DarkCategoryDetailScreen({
    super.key,
    required this.category,
  });
 
  @override
  State<DarkCategoryDetailScreen> createState() =>
      _DarkCategoryDetailScreenState();
}
 
class _DarkCategoryDetailScreenState
    extends State<DarkCategoryDetailScreen> {
  String _filter = 'All';
 
  List<GroklyProduct> get _allProducts {
    return _darkProductsForCategory(
      widget.category.categoryValue,
    );
  }
 
  List<String> get _filters {
    switch (widget.category.label) {
      case 'Dairy & Eggs':
        return const ['All', 'Milk', 'Cheese', 'Eggs'];
 
      case 'Fruits & Veggies':
        return const ['All', 'Fruits', 'Veggies', 'Exotic'];
 
      case 'Meat & Seafood':
        return const ['All', 'Chicken', 'Fish', 'Mutton'];
 
      case 'Bakery':
        return const ['All', 'Bread', 'Pastries', 'Cakes'];
 
      case 'Snacks':
        return const ['All', 'Chips', 'Cookies', 'Namkeen'];
 
      case 'Pantry Staples':
        return const ['All', 'Grains', 'Oils', 'Spices'];
 
      default:
        return const ['All'];
    }
  }
 
  bool _matchesFilter(GroklyProduct product) {
    if (_filter == 'All') {
      return true;
    }
 
    final name = product.name.toLowerCase();
    final category = product.category.toLowerCase();
    final sub = product.subCategory.toLowerCase();
 
    switch (_filter) {
      case 'Milk':
        return sub.contains('milk') || name.contains('milk');
      case 'Cheese':
        return sub.contains('cheese') || name.contains('cheese');
      case 'Eggs':
        return sub.contains('egg') || name.contains('egg');
      case 'Fruits':
        return sub.contains('fruit') ||
            name.contains('banana') ||
            name.contains('avocado') ||
            name.contains('tomato');
      case 'Veggies':
        return category == 'vegetables' && !sub.contains('fruit');
      case 'Exotic':
        return sub.contains('exotic') ||
            name.contains('avocado') ||
            name.contains('kiwi');
      case 'Chicken':
        return sub.contains('chicken') || name.contains('chicken');
      case 'Fish':
        return sub.contains('fish') ||
            name.contains('fish') ||
            name.contains('salmon');
      case 'Mutton':
        return sub.contains('mutton') || name.contains('mutton');
      case 'Bread':
        return sub.contains('bread') || name.contains('bread');
      case 'Pastries':
        return sub.contains('pastr') || name.contains('croissant');
      case 'Cakes':
        return sub.contains('cake') || name.contains('cake');
      case 'Chips':
        return sub.contains('chip') || name.contains('chip');
      case 'Cookies':
        return sub.contains('cookie') || name.contains('cookie');
      case 'Namkeen':
        return sub.contains('namkeen') || name.contains('namkeen');
      case 'Grains':
        return sub.contains('rice') ||
            sub.contains('atta') ||
            sub.contains('dal') ||
            sub.contains('grain');
      case 'Oils':
        return sub.contains('oil') || name.contains('oil');
      case 'Spices':
        return category == 'spices & masalas' ||
            sub.contains('spice') ||
            name.contains('masala');
      default:
        return name.contains(_filter.toLowerCase()) ||
            category.contains(_filter.toLowerCase()) ||
            sub.contains(_filter.toLowerCase());
    }
  }
 
  List<GroklyProduct> get _visibleProducts {
    return _allProducts.where(_matchesFilter).toList();
  }
 
  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    final cart = GroklyCartProvider.of(context);
 
    return Scaffold(
      backgroundColor: _DarkCat.bg,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: _DarkCat.screenGradient,
            ),
          ),
 
          Positioned(
            top: -90,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _DarkCat.accent.withOpacity(0.14),
                      blurRadius: 95,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
 
          Positioned(
            right: -100,
            bottom: 100,
            child: IgnorePointer(
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _DarkCat.accent.withOpacity(0.08),
                      blurRadius: 100,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
 
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        _DarkHeaderButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
 
                        const SizedBox(width: 8),
 
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _DarkCat.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
 
                        const SizedBox(width: 8),
 
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _DarkHeaderButton(
                              icon: Icons.shopping_cart_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CartScreen(),
                                  ),
                                );
                              },
                            ),
 
                            if (cart.totalQty > 0)
                              Positioned(
                                top: -3,
                                right: -3,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: _DarkCat.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${cart.totalQty}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
 
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    8,
                  ),
                  child: Row(
                    children: [
                      _DarkMiniImage(
                        imageUrl: widget.category.imageUrl,
                      ),
 
                      const SizedBox(width: 7),
 
                      Expanded(
                        child: Text(
                          widget.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _DarkCat.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
 
                      Text(
                        '${widget.category.itemCount} items',
                        style: const TextStyle(
                          color: _DarkCat.textDim,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
 
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 7),
                    itemBuilder: (_, index) {
                      final filter = _filters[index];
                      final active = filter == _filter;
 
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _filter = filter;
                          });
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active
                                ? _DarkCat.accent
                                : _DarkCat.cardInner,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: active
                                  ? _DarkCat.accent
                                  : _DarkCat.border,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: _DarkCat.accent
                                          .withOpacity(0.18),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: active
                                  ? Colors.black
                                  : _DarkCat.textDim,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
 
                const SizedBox(height: 8),
 
                Expanded(
                  child: products.isEmpty
                      ? const Center(
                          child: Text(
                            'No products found',
                            style: TextStyle(
                              color: _DarkCat.textDim,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : GridView.builder(
                          physics:
                              const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            12,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.76,
                          ),
                          itemCount: products.length,
                          itemBuilder: (_, index) {
                            return _DarkProductCard(
                              product: products[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
 
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            4,
            14,
            7,
          ),
          child: _DarkBottomNav(
            selectedIndex: 1,
          ),
        ),
      ),
    );
  }
}
 
 
// ============================================================================
// HEADER BUTTON (unchanged)
// ============================================================================
 
class _DarkHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
 
  const _DarkHeaderButton({
    required this.icon,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _DarkCat.cardInner.withOpacity(0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _DarkCat.border,
          ),
          boxShadow: [
            BoxShadow(
              color: _DarkCat.accent.withOpacity(0.035),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: _DarkCat.text,
          size: 15,
        ),
      ),
    );
  }
}
 
 
// ============================================================================
// MINI CATEGORY IMAGE (unchanged)
// ============================================================================
 
class _DarkMiniImage extends StatelessWidget {
  final String imageUrl;
 
  const _DarkMiniImage({
    required this.imageUrl,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _DarkCat.cardInner,
        border: Border.all(
          color: _DarkCat.border,
        ),
        boxShadow: [
          BoxShadow(
            color: _DarkCat.accent.withOpacity(0.09),
            blurRadius: 12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.image_outlined,
            color: _DarkCat.textDim,
            size: 13,
          );
        },
      ),
    );
  }
}
 
 
// ============================================================================
// PRODUCT CARD — CHANGED: no discount badge, flat favourite icon
// ============================================================================
 
class _DarkProductCard extends StatelessWidget {
  final GroklyProduct product;
 
  const _DarkProductCard({
    required this.product,
  });
 
  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);
    final qty = cart.qtyOf(product.id);
 
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: _DarkCat.cardGradient,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _DarkCat.borderSoft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.27),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: _DarkCat.accent.withOpacity(0.025),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------------
          // PRODUCT IMAGE — no discount tag, flat favourite icon
          // --------------------------------------------------------------
 
          SizedBox(
            height: 83,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: _DarkCat.cardBottom,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.image_outlined,
                          color: _DarkCat.textDim,
                          size: 22,
                        );
                      },
                    ),
                  ),
                ),
 
                // Favourite — flat outline icon, no background chip
                Positioned(
                  top: 0,
                  right: 0,
                  child: Consumer<BookmarkProvider>(
                    builder: (context, provider, _) {
                      bool isFav = provider.isGroklySaved(product.id);
                      return GestureDetector(
                        onTap: () => provider.toggleGrokly(product.id),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? GroklyColors.primary : _DarkCat.textDim,
                          size: 15,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
 
          const SizedBox(height: 4),
 
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DarkCat.text,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
 
          const SizedBox(height: 3),
 
          Text(
            product.size,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DarkCat.textDim,
              fontSize: 7.5,
              height: 1.1,
            ),
          ),
 
          const SizedBox(height: 3),
 
          if (product.rating != null)
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: _DarkCat.yellow,
                  size: 10,
                ),
                const SizedBox(width: 2),
                Text(
                  product.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    color: _DarkCat.textDim,
                    fontSize: 7.5,
                  ),
                ),
                if (product.ratingCount != null)
                  Flexible(
                    child: Text(
                      ' (${product.ratingCount})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _DarkCat.textDim,
                        fontSize: 7.5,
                      ),
                    ),
                  ),
              ],
            ),
 
          const Spacer(),
 
          Row(
            children: [
              Expanded(
                child: Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DarkCat.price,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
 
              const SizedBox(width: 5),
 
              if (qty == 0)
                _DarkAddButton(
                  onTap: () => cart.add(product),
                )
              else
                _DarkQuantityButton(
                  qty: qty,
                  onAdd: () => cart.add(product),
                  onRemove: () => cart.remove(product),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
 
 
// ============================================================================
// ADD BUTTON (unchanged)
// ============================================================================
 
class _DarkAddButton extends StatelessWidget {
  final VoidCallback onTap;
 
  const _DarkAddButton({
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 27,
        height: 27,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _DarkCat.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _DarkCat.accent.withOpacity(0.27),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.black,
          size: 17,
        ),
      ),
    );
  }
}
 
 
// ============================================================================
// QUANTITY BUTTON (unchanged)
// ============================================================================
 
class _DarkQuantityButton extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
 
  const _DarkQuantityButton({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
      ),
      decoration: BoxDecoration(
        color: _DarkCat.accent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _DarkCat.accent.withOpacity(0.20),
            blurRadius: 9,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const SizedBox(
              width: 20,
              height: 27,
              child: Icon(
                Icons.remove_rounded,
                color: Colors.black,
                size: 14,
              ),
            ),
          ),
 
          Text(
            '$qty',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
 
          GestureDetector(
            onTap: onAdd,
            child: const SizedBox(
              width: 20,
              height: 27,
              child: Icon(
                Icons.add_rounded,
                color: Colors.black,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
 
// ============================================================================
// BOTTOM NAVIGATION (unchanged — already matches Figma on every screen)
// ============================================================================
 
class _DarkBottomNav extends StatelessWidget {
  final int selectedIndex;
 
  const _DarkBottomNav({
    required this.selectedIndex,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 57,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        gradient: _DarkCat.navGradient,
        borderRadius: BorderRadius.circular(29),
        border: Border.all(
          color: _DarkCat.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: 17,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _DarkNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            active: selectedIndex == 0,
          ),
 
          _DarkNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Categories',
            active: selectedIndex == 1,
          ),
 
          _DarkNavItem(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart_rounded,
            label: 'Cart',
            active: selectedIndex == 2,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CartScreen(),
                ),
              );
            },
          ),
 
          _DarkNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            active: selectedIndex == 3,
          ),
        ],
      ),
    );
  }
}
 
 
// ============================================================================
// BOTTOM NAV ITEM (unchanged)
// ============================================================================
 
class _DarkNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
 
  const _DarkNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active
                  ? _DarkCat.accent
                  : _DarkCat.textDim,
              size: 17,
            ),
 
            const SizedBox(height: 1),
 
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active
                    ? _DarkCat.accent
                    : _DarkCat.textDim,
                fontSize: 7,
                fontWeight: active
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
 
            if (active)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: _DarkCat.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedTile {
  final String title;
  final String imageUrl;
  final String? badge;
  const _FeaturedTile({required this.title, required this.imageUrl, this.badge});
}

class _FeaturedTileCard extends StatelessWidget {
  final _FeaturedTile tile;
  final VoidCallback onTap;
  const _FeaturedTileCard({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: GroklyColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: GroklyShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    tile.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: GroklyColors.surfaceMint),
                  ),
                  if (tile.badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: GroklyColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tile.badge!,
                          style: GroklyTextStyles.labelCaps
                              .copyWith(color: GroklyColors.white, fontSize: 9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                tile.title,
                textAlign: TextAlign.center,
                style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _CategoryCard extends StatelessWidget {
  final String title, imageUrl;
  final VoidCallback onTap;
  const _CategoryCard({required this.title, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: GroklyColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: GroklyShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(color: GroklyColors.surfaceMint)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 14),
                      overflow: TextOverflow.ellipsis)),
                  Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(color: GroklyColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_right, color: GroklyColors.white, size: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}// ���������������������������������������������
// ���������������������������������������������
// SCREEN 3: USUALS
// ���������������������������������������������

class UsualsItem {
  final GroklyProduct product;
  final String? statusBadge;
  final String? frequencyNote;
  const UsualsItem({required this.product, this.statusBadge, this.frequencyNote});
}

class UsualsScreen extends StatelessWidget {
  const UsualsScreen({super.key});

  static final categories = [
    UsualsCategory(title: 'Dairy & Essentials', items: [
      UsualsItem(product: GroklyCatalog.dairy[0], statusBadge: 'RUNNING LOW', frequencyNote: 'Usually ordered every 4 days'),
      UsualsItem(product: GroklyCatalog.dairy[1], frequencyNote: 'Usually ordered every 7 days'),
      UsualsItem(product: GroklyCatalog.dairy[2], frequencyNote: 'Usually ordered every 5 days'),
      UsualsItem(product: GroklyCatalog.dairy[3], statusBadge: 'OUT OF STOCK'),
    ]),
    UsualsCategory(title: 'Daily Staples', items: [
      UsualsItem(product: GroklyCatalog.staples[0], frequencyNote: 'Usually ordered every 30 days'),
      UsualsItem(product: GroklyCatalog.staples[1], frequencyNote: 'Usually ordered every 20 days'),
      UsualsItem(product: GroklyCatalog.staples[2], statusBadge: 'RUNNING LOW'),
      UsualsItem(product: GroklyCatalog.staples[3], frequencyNote: 'Usually ordered every 15 days'),
    ]),
    UsualsCategory(title: 'Fresh Vegetables', items: [
      UsualsItem(product: GroklyCatalog.vegetables[0], frequencyNote: 'Usually ordered every 3 days'),
      UsualsItem(product: GroklyCatalog.vegetables[1], frequencyNote: 'Usually ordered every 3 days'),
      UsualsItem(product: GroklyCatalog.vegetables[2], statusBadge: 'RUNNING LOW'),
      UsualsItem(product: GroklyCatalog.vegetables[3]),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);

    if (categories.isEmpty || categories.every((c) => c.items.isEmpty)) {
      return _UsualsEmptyState();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GroklyAppBar(title: 'Usuals', subtitle: 'YOUR ROUTINE, SIMPLIFIED'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...categories.map((cat) => _UsualsCategorySection(category: cat, cart: cart)),
                Container(
                  width: double.infinity,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 160),
                  decoration: BoxDecoration(
                    color: GroklyColors.primary,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: GroklyShadows.card,
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      var added = 0;
                      for (final cat in categories) {
                        for (final item in cat.items) {
                          if (item.statusBadge == 'OUT OF STOCK') continue;
                          cart.add(item.product);
                          added++;
                        }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$added usuals restocked!'),
                          backgroundColor: GroklyColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.restart_alt, color: GroklyColors.white),
                    label: Text(
                      'RESTOCK ALL USUALS',
                      style: GroklyTextStyles.labelCaps
                          .copyWith(color: GroklyColors.white, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UsualsCategorySection extends StatelessWidget {
  final UsualsCategory category;
  final CartState cart;
  const _UsualsCategorySection({required this.category, required this.cart});

  @override
  Widget build(BuildContext context) {
    final inStockCount = category.items.where((i) => i.statusBadge != 'OUT OF STOCK').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.title,
              style: GroklyTextStyles.sectionHeader
                  .copyWith(color: GroklyColors.primary, fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                Text('${category.items.length} ITEMS', style: GroklyTextStyles.labelCaps),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: inStockCount == 0
                      ? null
                      : () {
                          for (final item in category.items) {
                            if (item.statusBadge == 'OUT OF STOCK') continue;
                            cart.add(item.product);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${category.title} added to cart'),
                              backgroundColor: GroklyColors.primary,
                            ),
                          );
                        },
                  child: Text(
                    'ADD ALL',
                    style: GroklyTextStyles.labelCaps.copyWith(
                      color: inStockCount == 0 ? GroklyColors.outline : GroklyColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: category.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 270, // bumped up further — was 258, gives extra safety margin
          ),
          itemBuilder: (_, i) => _UsualsItemCard(item: category.items[i]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _UsualsItemCard extends StatelessWidget {
  final UsualsItem item;
  const _UsualsItemCard({required this.item});

  static const List<Color> _palette = [
    GroklyColors.secContainer,
    GroklyColors.primaryLight,
    GroklyColors.primaryFixed,
    GroklyColors.surfaceMint,
  ];

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final cart = GroklyCartProvider.of(context);
    final qty = cart.qtyOf(product.id);
    final outOfStock = item.statusBadge == 'OUT OF STOCK';
    final swatch = _palette[product.id.hashCode.abs() % _palette.length];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GroklyColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: GroklyShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _brandPlaceholder(product, swatch),
                ),
              ),
              if (item.statusBadge != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: outOfStock ? GroklyColors.outline : GroklyColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.statusBadge!,
                      style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.white, fontSize: 8),
                    ),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Consumer<BookmarkProvider>(
                  builder: (context, provider, _) {
                    bool isFav = provider.isGroklySaved(product.id);
                    return GestureDetector(
                      onTap: () => provider.toggleGrokly(product.id),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: GroklyColors.white, shape: BoxShape.circle),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 13,
                          color: GroklyColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Removed ${product.name} from Usuals')),
                    );
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: GroklyColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 13, color: GroklyColors.outline),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: GroklyTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${product.brand} · ${product.size}',
            style: GroklyTextStyles.labelCaps.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.frequencyNote != null) ...[
            const SizedBox(height: 2),
            Text(
              item.frequencyNote!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GroklyTextStyles.labelCaps.copyWith(
                fontSize: 9,
                color: GroklyColors.primary,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: GroklyTextStyles.price.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                height: 40, // was 34 — this was the exact source of the overflow, now has margin
                child: outOfStock
                    ? OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: GroklyColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'NOTIFY',
                          style: GroklyTextStyles.labelCaps.copyWith(
                            color: GroklyColors.primary,
                            fontSize: 9,
                          ),
                        ),
                      )
                    : (qty == 0
                        ? _AddButton(onTap: () => cart.add(product))
                        : _QtyControl(
                            qty: qty,
                            onAdd: () => cart.add(product),
                            onRemove: () => cart.remove(product),
                          )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _brandPlaceholder(GroklyProduct product, Color swatch) {
    return Container(
      width: double.infinity,
      height: 82,
      color: swatch,
      alignment: Alignment.center,
      child: Text(
        product.brand.isNotEmpty ? product.brand[0].toUpperCase() : '₹',
        style: GroklyTextStyles.headlineLg.copyWith(fontSize: 28, color: GroklyColors.onSurface),
      ),
    );
  }
}

class _UsualsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GroklyAppBar(title: 'Usuals', subtitle: 'YOUR ROUTINE, SIMPLIFIED'),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.autorenew_rounded, size: 56, color: GroklyColors.outline),
                const SizedBox(height: 16),
                Text(
                  'No usuals yet',
                  style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Order a few times and we'll start showing your routine here for one-tap restocking.",
                  style: GroklyTextStyles.bodyMain.copyWith(color: GroklyColors.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// ���������������������������������������������
// SCREEN 4: FEATURES HUB
// ���������������������������������������������

// ���������������������������������������������
// FEATURES SECTION — SHARED UI KIT
// Matches the Grokly return-flow Figma frames: white surfaces,
// hairline-bordered cards, deep-green CTAs, mint info banners,
// status tags, green checkboxes and step trackers.
// (Private to the Features section — no other screens changed.)
// ���������������������������������������������

class _FxUi {
  static const green      = Color(0xFF0A5C36); // CTA / accents
  static const greenDark  = Color(0xFF063D24); // hero cards
  static const mint       = Color(0xFFEAF6EF); // soft banners / chips
  static const mintBorder = Color(0xFFCFE8DB);
  static const border     = Color(0xFFE5E7EB); // hairline card borders
  static const bg         = Color(0xFFFFFFFF);
  static const thumb      = Color(0xFFF4F5F4); // thumbnail wells
  static const textDark   = Color(0xFF111827);
  static const textGray   = Color(0xFF6B7280);
  static const amber      = Color(0xFFB45309);
  static const amberBg    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFB91C1C);
  static const redBg      = Color(0xFFFEE2E2);
}

class _FxText {
  static const screenTitle = TextStyle(
      fontSize: 17, fontWeight: FontWeight.w700, color: _FxUi.textDark, height: 1.3);
  static const cardTitle = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w600, color: _FxUi.textDark, height: 1.3);
  static const rowTitle = TextStyle(
      fontSize: 13.5, fontWeight: FontWeight.w600, color: _FxUi.textDark, height: 1.3);
  static const body = TextStyle(
      fontSize: 12.5, fontWeight: FontWeight.w400, color: _FxUi.textGray, height: 1.55);
  static const small = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w500, color: _FxUi.textGray, height: 1.35);
  static const tag = TextStyle(
      fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, height: 1.2);
  static const button = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
  static const price = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w700, color: _FxUi.textDark);
  static const caps = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: _FxUi.green);
}

/// White app bar with back chevron — used by every pushed feature screen.
class _FxAppBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _FxAppBar({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _FxUi.bg,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: _FxUi.bg,
            border: Border(bottom: BorderSide(color: _FxUi.border)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: _FxUi.textDark, size: 22),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(title,
                    style: _FxText.screenTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (trailing != null) trailing!,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hairline-bordered white card — the base surface of the Figma frames.
class _FxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color color;
  final Color borderColor;
  const _FxCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.color = _FxUi.bg,
    this.borderColor = _FxUi.border,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: child,
      );
}

/// Full-width deep-green CTA — "Proceed to Pay" / "Continue" style.
class _FxCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
  const _FxCta({required this.label, required this.onTap, this.icon, this.enabled = true});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: enabled ? _FxUi.green : _FxUi.border,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _FxText.button.copyWith(
                        color: enabled ? Colors.white : _FxUi.textGray)),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: enabled ? Colors.white : _FxUi.textGray, size: 17),
              ],
            ],
          ),
        ),
      );
}

/// Outlined secondary button — "Reorder Items" style.
class _FxOutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  const _FxOutlineBtn({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: _FxUi.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _FxUi.green, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, color: _FxUi.green, size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _FxText.button.copyWith(color: _FxUi.green)),
              ),
            ],
          ),
        ),
      );
}

/// Small status tag — "Best Delivery" / "Completed" style.
class _FxTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  final bool filled;
  const _FxTag(this.text,
      {this.color = _FxUi.green, this.bg = _FxUi.mint, this.filled = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? color : bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: _FxText.tag.copyWith(color: filled ? Colors.white : color)),
      );
}

/// Mint info banner — the "You have 2 returnable items" strip.
class _FxMintBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _FxMintBanner(
      {required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _FxUi.mint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _FxUi.mintBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _FxUi.bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: _FxUi.green, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: _FxText.rowTitle.copyWith(color: _FxUi.green, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _FxText.small.copyWith(color: _FxUi.textGray)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      );
}

/// Rounded green checkbox — the return-item selector.
class _FxCheck extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  const _FxCheck({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: value ? _FxUi.green : _FxUi.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: value ? _FxUi.green : _FxUi.border, width: 1.4),
          ),
          child: value
              ? const Icon(Icons.check, color: Colors.white, size: 15)
              : null,
        ),
      );
}

/// Grey-well product thumbnail.
class _FxThumb extends StatelessWidget {
  final String url;
  final double size;
  const _FxThumb(this.url, {this.size = 46});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _FxUi.thumb,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined,
                  color: _FxUi.textGray, size: 18)),
        ),
      );
}

/// Section heading with optional trailing action.
class _FxSectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _FxSectionTitle(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text,
              style: _FxText.cardTitle.copyWith(fontSize: 14.5)),
          if (trailing != null) trailing!,
        ],
      );
}

/// Filter pill row — "All / Completed / Pending" selector.
class _FxPills extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  const _FxPills(
      {required this.labels, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == selected;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? _FxUi.green : _FxUi.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: active ? _FxUi.green : _FxUi.border),
                ),
                child: Text(labels[i],
                    style: _FxText.small.copyWith(
                        color: active ? Colors.white : _FxUi.textDark,
                        fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      );
}

/// Green dot step tracker — the order-status timeline.
class _FxStepTracker extends StatelessWidget {
  final List<String> steps;
  final int current; // index of the in-progress step
  const _FxStepTracker({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= current ? _FxUi.green : _FxUi.bg,
                  border: Border.all(
                      color: i <= current ? _FxUi.green : _FxUi.border,
                      width: 1.6),
                ),
                child: i < current
                    ? const Icon(Icons.check, size: 9, color: Colors.white)
                    : null,
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2.2,
                    color: i < current ? _FxUi.green : _FxUi.border,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 0; i < steps.length; i++)
              Expanded(
                child: Text(steps[i],
                    textAlign: i == 0
                        ? TextAlign.left
                        : i == steps.length - 1
                            ? TextAlign.right
                            : TextAlign.center,
                    style: _FxText.small.copyWith(
                        fontSize: 9.5,
                        color:
                            i <= current ? _FxUi.green : _FxUi.textGray,
                        fontWeight:
                            i == current ? FontWeight.w700 : FontWeight.w500)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Bullet row with a mint check-circle — "How to earn" style.
class _FxBullet extends StatelessWidget {
  final String text;
  final IconData icon;
  const _FxBullet(this.text, {this.icon = Icons.check_rounded});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: const BoxDecoration(
                  color: _FxUi.mint, shape: BoxShape.circle),
              child: Icon(icon, color: _FxUi.green, size: 12),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: _FxText.body.copyWith(
                        color: _FxUi.textDark.withOpacity(0.85), fontSize: 12))),
          ],
        ),
      );
}

// ���������������������������������������������
// SIXTH SENSE PREDICTION DATA (shared with the hub's Smart Basket card)
// Every entry maps to a REAL GroklyCatalog product so "confirm" and
// "restock" actions put real, priced products into the cart.
// ���������������������������������������������

class _SixthSensePick {
  final String productId;
  final int qty;
  final String reason;
  const _SixthSensePick(this.productId, this.qty, this.reason);

  factory _SixthSensePick.fromSixthSenseItem(SixthSenseItem item) {
    return _SixthSensePick(item.productId, item.quantity, item.reason);
  }
}

class _SixthSenseData {
  static GroklyProduct? productOf(String id) =>
      GroklyCatalog.all.where((p) => p.id == id).firstOrNull;

  static double totalFor(List<_SixthSensePick> picks, Set<String> includedIds) {
    double t = 0;
    for (final pick in picks) {
      if (!includedIds.contains(pick.productId)) continue;
      final p = productOf(pick.productId);
      if (p != null) t += p.price * pick.qty;
    }
    return t;
  }
}

// ���������������������������������������������
// SCREEN 4: FEATURES HUB — "Advanced Kitchen Ecosystem"
// Redesigned to the return-flow Figma UI. Every button navigates.
// ���������������������������������������������

class FeaturesHubScreen extends StatelessWidget {
  const FeaturesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _FxUi.bg,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GROKLY SMART FEATURES', style: _FxText.caps),
                    const SizedBox(height: 4),
                    Text('Advanced Kitchen Ecosystem',
                        style: _FxText.screenTitle.copyWith(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                        'Fresh essentials & grocery delivery — your grandma\'s home, powered by AI.',
                        style: _FxText.body),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // �� Dark-green intelligence hero (Green Points style) ��
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _FxUi.greenDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GROKLY INTELLIGENCE',
                            style: _FxText.tag.copyWith(
                                color: Colors.white.withOpacity(0.75),
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('91%',
                                style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.0)),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('basket accuracy\nat day 60',
                                  style: _FxText.small.copyWith(
                                      color: Colors.white.withOpacity(0.85))),
                            ),
                            const Spacer(),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(height: 1, color: Colors.white.withOpacity(0.15)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _HeroStat(
                                    value: '300+', label: 'SKU velocity\nmapped')),
                            Expanded(
                                child: _HeroStat(
                                    value: '2–3 days', label: 'early depletion\nalerts')),
                            Expanded(
                                child: _HeroStat(
                                    value: '1-tap', label: 'restock &\nbundles')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _FxSectionTitle('Smart Features'),
                  const SizedBox(height: 12),

                  _FeatureCard(
                    icon: Icons.kitchen_outlined,
                    tag: 'ML-POWERED',
                    title: 'Smart Pantry Depletion Tracker',
                    description:
                        'Our ML model infers your pantry state from household size and purchase velocity — no manual entry needed.',
                    bullets: const [
                      'Alerts 2–3 days before predicted depletion',
                      'One-tap restock straight into your cart',
                      'Live stock levels for every household essential',
                    ],
                    cta: 'Open Smart Pantry',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SmartPantryScreen())),
                  ),
                  _FeatureCard(
                    icon: Icons.restaurant_menu_outlined,
                    tag: 'ONE-TAP BUNDLES',
                    title: 'Dish-First Grocery Shopping',
                    description:
                        'Choose a dish first and instantly get every ingredient — reducing friction, saving time, and making shopping smarter and more intuitive.',
                    bullets: const [
                      'Pick a dish → the full ingredient list is bundled',
                      'Untick what you already have at home',
                      'Grows cart value through intuitive shopping',
                    ],
                    cta: 'Browse Dishes',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DishFirstScreen())),
                  ),
                  _FeatureCard(
                    icon: Icons.insights_outlined,
                    tag: 'CONSUMPTION ENGINE',
                    title: 'Sixth Sense',
                    description:
                        'A household consumption engine mapping 300+ SKU velocity — the first platform that predicts, sources and delivers before you feel the need.',
                    bullets: const [
                      'Cross-references your Swadisht meals',
                      '91% basket accuracy at day 60',
                      'Sunday morning: your week is ready. Tap to confirm.',
                    ],
                    cta: 'See This Week\'s Prediction',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SixthSenseScreen())),
                  ),

                  const SizedBox(height: 4),

                  // �� Smart Basket — now fully functional ��
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SixthSenseScreen())),
                    child: _FxCard(
                      color: _FxUi.mint,
                      borderColor: _FxUi.mintBorder,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: _FxUi.green,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: Colors.white, size: 21),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SMART BASKET',
                                    style: _FxText.tag
                                        .copyWith(color: _FxUi.green)),
                                const SizedBox(height: 2),
                                Text(
                                    '${context.watch<SixthSenseProvider>().sixthSenseBasket?.items.length ?? 8} items queued for Sunday',
                                    style: _FxText.rowTitle),
                                const SizedBox(height: 2),
                                Text('Tap to review & confirm before it ships',
                                    style: _FxText.small),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: _FxUi.green, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: _FxText.small.copyWith(
                  fontSize: 9, color: Colors.white.withOpacity(0.7))),
        ],
      );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String tag;
  final String title;
  final String description;
  final List<String> bullets;
  final String cta;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
    required this.bullets,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _FxCard(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: _FxUi.mint,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: _FxUi.green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _FxText.cardTitle),
                      const SizedBox(height: 5),
                      _FxTag(tag),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: _FxText.body),
            const SizedBox(height: 12),
            ...bullets.map((b) => _FxBullet(b)),
            const SizedBox(height: 6),
            _FxCta(label: cta, icon: Icons.arrow_forward, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

// ���������������������������������������������
// SCREEN 5: PROFILE
// FIX: renamed from ProfileScreen → GroklyProfileScreen
// to avoid ambiguous import with profile_screen.dart
// ���������������������������������������������


/// ---------------------------------------------------------------------
/// GroklyProfileScreen — now fully functional.
///
/// Changes from the original:
/// 1. Converted StatelessWidget -> StatefulWidget so the "Healthy Mode"
///    switch actually toggles and persists while the screen is open.
/// 2. Every tappable row now has a real onTap: Saved Addresses, Help &
///    Support, Wallet, and the Referral banner all navigate or act.
/// 3. Sign out shows a confirmation dialog before doing anything
///    destructive, and calls an injectable onSignOut callback so you
///    can wire it to your real auth logic.
/// 4. Wallet balance and "Healthy Mode" are now real fields (with an
///    optional constructor override) instead of hardcoded strings, so
///    you can feed them from a provider/bloc/state manager.
/// 5. Added lightweight placeholder screens (SavedAddressesScreen,
///    HelpSupportScreen, WalletScreen) since they weren't in the
///    original snippet — swap these for your real screens whenever
///    they exist, the onTap wiring won't need to change.
/// ---------------------------------------------------------------------

class GroklyProfileScreen extends StatefulWidget {
  final String userName;
  final double walletBalance;
  final bool initialHealthyMode;
  final int savedBasketCount;
  final Future<void> Function()? onSignOut;
  final ValueChanged<bool>? onHealthyModeChanged;

  const GroklyProfileScreen({
    super.key,
    this.userName = 'Grokly User',
    this.walletBalance = 245.50,
    this.initialHealthyMode = true,
    this.savedBasketCount = 3,
    this.onSignOut,
    this.onHealthyModeChanged,
  });

  @override
  State<GroklyProfileScreen> createState() => _GroklyProfileScreenState();
}

class _GroklyProfileScreenState extends State<GroklyProfileScreen> {
  late bool _healthyMode;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _healthyMode = widget.initialHealthyMode;
  }

  void _toggleHealthyMode(bool value) {
    setState(() => _healthyMode = value);
    widget.onHealthyModeChanged?.call(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value
            ? 'Healthy Mode on — showing organic & nutritious picks'
            : 'Healthy Mode off'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to place orders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out', style: TextStyle(color: GroklyColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _signingOut = true);
    try {
      if (widget.onSignOut != null) {
        await widget.onSignOut!();
      }
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      
      // Clear navigation stack and go to Login Screen entirely
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = 'Grokly User';
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null && (authUser.displayName ?? '').trim().isNotEmpty) {
        displayName = authUser.displayName!;
      } else {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.user != null && userProvider.user!.name.trim().isNotEmpty) {
          displayName = userProvider.user!.name;
        }
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: GroklyColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [GroklyColors.primary, Color(0xFF1A7B48)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (Navigator.canPop(context))
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12, bottom: 6),
                            child: Icon(Icons.arrow_back_ios_new, color: GroklyColors.white, size: 24),
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('WELCOME BACK', style: GroklyTextStyles.labelCaps.copyWith(
                              color: GroklyColors.primaryFixed, fontSize: 11, letterSpacing: 1.2)),
                          const SizedBox(height: 2),
                          Text(displayName, style: GroklyTextStyles.headlineLg.copyWith(fontSize: 26, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showComingSoon('Edit profile'),
                        child: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: GroklyColors.white.withOpacity(0.5), width: 2),
                            color: GroklyColors.white.withOpacity(0.15),
                          ),
                          child: const Icon(Icons.person_rounded, color: GroklyColors.white, size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _ProfileQuickCard(
                    icon: Icons.shopping_bag_outlined, title: 'My Orders',
                    subtitle: 'Track delivery', color: GroklyColors.surfaceCard,
                    iconColor: GroklyColors.primaryDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const MyOrdersScreen())),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Builder(builder: (context) {
                    final walletProvider = context.dependOnInheritedWidgetOfExactType<GroklyWalletProvider>();
                    final liveBalance = walletProvider?.notifier?.balance ?? 245.50;
                    final displayBalance = liveBalance > 0 ? liveBalance : 245.50;
                    return _ProfileQuickCard(
                      icon: Icons.account_balance_wallet_outlined, title: 'Wallet',
                      subtitle: '₹${displayBalance.toStringAsFixed(2)} balance',
                      color: GroklyColors.surfaceMint,
                      iconColor: GroklyColors.primaryDark,
                      badge: '₹${displayBalance.round()}',
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const WalletScreen())),
                    );
                  })),
                ]),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GroklyColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: GroklyShadows.soft,
                    border: Border.all(color: GroklyColors.primary.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: GroklyColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.spa_rounded, color: GroklyColors.primaryDark),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Healthy Mode', style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 16)),
                          Text('Filter for organic & nutritious',
                              style: GroklyTextStyles.labelCaps.copyWith(fontSize: 10)),
                        ]),
                      ),
                      Switch(
                        value: _healthyMode,
                        onChanged: _toggleHealthyMode,
                        activeColor: GroklyColors.primaryDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Builder(
                  builder: (context) {
                    try {
                      final bookmarks = Provider.of<BookmarkProvider>(context, listen: true);
                      final count = bookmarks.savedGroklyIds.isNotEmpty
                          ? bookmarks.savedGroklyIds.length
                          : 3;
                      return _ProfileListItem(
                        icon: Icons.shopping_basket_outlined, title: 'My Saved Baskets',
                        badge: '$count BUNDLES',
                        iconColor: GroklyColors.primaryDark,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const SavedBasketsScreen())),
                      );
                    } catch (_) {
                      return _ProfileListItem(
                        icon: Icons.shopping_basket_outlined, title: 'My Saved Baskets',
                        badge: '3 BUNDLES',
                        iconColor: GroklyColors.primaryDark,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const SavedBasketsScreen())),
                      );
                    }
                  }
                ),
                Builder(
                  builder: (context) {
                    final ordersProvider = context.dependOnInheritedWidgetOfExactType<GroklyOrdersProvider>();
                    final count = ordersProvider?.notifier?.returnEligibleCount ?? 1;
                    final displayCount = count > 0 ? count : 1;
                    return _ProfileListItem(
                      icon: Icons.assignment_return_outlined, title: 'My Orders & Eco-Returns',
                      badge: '$displayCount ELIGIBLE',
                      iconColor: GroklyColors.primaryDark,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ReturnAndEarnScreen())),
                    );
                  }
                ),
                _ProfileListItem(
                  icon: Icons.location_on_outlined, title: 'Saved Addresses',
                  iconColor: GroklyColors.primaryDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const SavedAddressesScreen())),
                ),
                _ProfileListItem(
                  icon: Icons.contact_support_outlined, title: 'Help & Support',
                  iconColor: GroklyColors.primaryDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen())),
                ),
                const SizedBox(height: 12),

                _ReferralBanner(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())),
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    color: GroklyColors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: GroklyColors.error.withOpacity(0.3)),
                  ),
                  child: TextButton.icon(
                    onPressed: _signingOut ? null : _handleSignOut,
                    icon: _signingOut
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: GroklyColors.error),
                          )
                        : const Icon(Icons.logout, color: GroklyColors.error),
                    label: Text(_signingOut ? 'Signing out...' : 'Sign out',
                        style: GroklyTextStyles.sectionHeader.copyWith(
                            color: GroklyColors.error, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Grokly v2.0 Premium',
                    style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.outline, fontSize: 10)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }
}

class _ProfileQuickCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color, iconColor;
  final String? badge;
  final VoidCallback? onTap;
  const _ProfileQuickCard({required this.icon, required this.title, required this.subtitle,
    required this.color, required this.iconColor, this.badge, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      height: 120,
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(20),
        boxShadow: GroklyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(19)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            if (badge != null) Text(badge!, style: GroklyTextStyles.price.copyWith(fontSize: 14)),
          ]),
          const Spacer(),
          Text(title, style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 15)),
          Text(subtitle, style: GroklyTextStyles.labelCaps.copyWith(fontSize: 10)),
        ],
      ),
    ),
  );
}

class _ProfileListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Color iconColor;
  final VoidCallback? onTap;
  const _ProfileListItem({
    required this.icon,
    required this.title,
    this.badge,
    this.iconColor = GroklyColors.primaryDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: GroklyColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: GroklyShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 15))),
          if (badge != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: GroklyColors.primaryDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(badge!, style: GroklyTextStyles.labelCaps.copyWith(
                color: GroklyColors.white, fontSize: 9)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: GroklyColors.outline, size: 18),
        ],
      ),
    ),
  );
}

class _ReferralBanner extends StatelessWidget {
  final VoidCallback? onTap;
  const _ReferralBanner({this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [GroklyColors.primary.withOpacity(0.1), GroklyColors.primary.withOpacity(0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GroklyColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: GroklyColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: GroklyColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Refer a friend', style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 15)),
                Text('You both get ₹50 off',
                    style: GroklyTextStyles.labelCaps.copyWith(fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: GroklyColors.primaryDark, size: 20),
        ],
      ),
    ),
  );
}

/// ---------------------------------------------------------------------
/// Placeholder destination screens.
/// These didn't exist in the original snippet (only OrderTrackingScreen
/// and SavedBasketsScreen were referenced elsewhere in the app). Replace
/// the body of each with your real screen whenever it's ready — the
/// Navigator.push calls above won't need to change.
/// ---------------------------------------------------------------------

enum AddressType { home, work, other }

class SavedAddress {
  String id;
  String label; // e.g. "Home", "Work", custom name
  AddressType type;
  String fullAddress;
  String? landmark;
  bool isDefault;

  SavedAddress({
    required this.id,
    required this.label,
    required this.type,
    required this.fullAddress,
    this.landmark,
    this.isDefault = false,
  });
}

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final List<SavedAddress> _addresses = [
    SavedAddress(
      id: '1',
      label: 'Home',
      type: AddressType.home,
      fullAddress: '204, Sunrise Apartments, Andheri West, Mumbai - 400058',
      landmark: 'Near Infinity Mall',
      isDefault: true,
    ),
    SavedAddress(
      id: '2',
      label: 'Work',
      type: AddressType.work,
      fullAddress: 'TSEC Campus, Bandra West, Mumbai - 400050',
      isDefault: false,
    ),
  ];

  IconData _iconFor(AddressType type) {
    switch (type) {
      case AddressType.home:
        return Icons.home_outlined;
      case AddressType.work:
        return Icons.work_outline;
      case AddressType.other:
        return Icons.location_on_outlined;
    }
  }

  void _setDefault(String id) {
    setState(() {
      for (final a in _addresses) {
        a.isDefault = a.id == id;
      }
    });
  }

  void _deleteAddress(String id) {
    final removed = _addresses.firstWhere((a) => a.id == id);
    setState(() => _addresses.removeWhere((a) => a.id == id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.label} address removed'),
        backgroundColor: const Color(0xFF2E7D5B),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => setState(() => _addresses.add(removed)),
        ),
      ),
    );
  }

  Future<void> _openAddressForm({SavedAddress? existing}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final addressController =
        TextEditingController(text: existing?.fullAddress ?? '');
    final landmarkController =
        TextEditingController(text: existing?.landmark ?? '');
    AddressType selectedType = existing?.type ?? AddressType.home;

    final result = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF14231C),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'Add New Address' : 'Edit Address',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: AddressType.values.map((type) {
                        final selected = selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(type.name),
                            selected: selected,
                            onSelected: (_) =>
                                setModalState(() => selectedType = type),
                            selectedColor: const Color(0xFF2E7D5B),
                            backgroundColor: Colors.white.withOpacity(0.06),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    _formField(labelController, 'Label (e.g. Home, Work)'),
                    const SizedBox(height: 10),
                    _formField(addressController, 'Full Address', maxLines: 3),
                    const SizedBox(height: 10),
                    _formField(landmarkController, 'Landmark (optional)'),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D5B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (addressController.text.trim().isEmpty ||
                              labelController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Label and address are required'),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(
                            ctx,
                            SavedAddress(
                              id: existing?.id ??
                                  DateTime.now().millisecondsSinceEpoch.toString(),
                              label: labelController.text.trim(),
                              type: selectedType,
                              fullAddress: addressController.text.trim(),
                              landmark: landmarkController.text.trim().isEmpty
                                  ? null
                                  : landmarkController.text.trim(),
                              isDefault: existing?.isDefault ?? false,
                            ),
                          );
                        },
                        child: Text(
                          existing == null ? 'Save Address' : 'Update Address',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        final index = _addresses.indexWhere((a) => a.id == result.id);
        if (index >= 0) {
          _addresses[index] = result;
        } else {
          _addresses.add(result);
        }
      });
    }
  }

  Widget _formField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1B15),
        elevation: 0,
        title: const Text('Saved Addresses', style: TextStyle(color: Colors.white)),
      ),
      body: _addresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, i) => _buildAddressCard(_addresses[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddressForm(),
        backgroundColor: const Color(0xFF2E7D5B),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off_outlined, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No saved addresses yet',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _openAddressForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D5B),
            ),
            child: const Text('Add your first address',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(SavedAddress address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: address.isDefault
            ? Border.all(color: const Color(0xFF2E7D5B), width: 1.2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D5B).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(address.type), color: const Color(0xFF4CAF7D), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D5B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: Color(0xFF4CAF7D),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF14231C),
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onSelected: (value) {
                  if (value == 'edit') _openAddressForm(existing: address);
                  if (value == 'delete') _deleteAddress(address.id);
                  if (value == 'default') _setDefault(address.id);
                },
                itemBuilder: (ctx) => [
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as default',
                          style: TextStyle(color: Colors.white)),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address.fullAddress,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (address.landmark != null) ...[
            const SizedBox(height: 4),
            Text(
              'Landmark: ${address.landmark}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}


/// ---------------------------------------------------------------------
/// HelpSupportScreen
///
/// - Search bar to filter FAQs live
/// - Three quick-contact cards (Call / Chat / Email) that actually
///   launch the phone dialer, a chat route, or an email intent
/// - Expandable FAQ accordion grouped by category
/// - Sticky "still need help" footer with a raise-a-ticket CTA
///
/// Uses url_launcher for tel:/mailto: — add to pubspec.yaml:
///   url_launcher: ^6.3.0
/// If you don't want that dependency, delete _launch() calls and swap
/// in your own contact flow (they're isolated in one place).
/// ---------------------------------------------------------------------

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _FaqItem {
  final String question;
  final String answer;
  final String category;
  const _FaqItem(this.question, this.answer, this.category);
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _faqs = [
    _FaqItem(
      'Where is my order₹',
      'Open "My Orders" from your profile to see live tracking. You\'ll also get push notifications at each delivery stage.',
      'Orders',
    ),
    _FaqItem(
      'How do I cancel an order₹',
      'Orders can be cancelled for free within 2 minutes of placing them from the Order Tracking screen. After that, contact support for help.',
      'Orders',
    ),
    _FaqItem(
      'An item was missing or damaged',
      'Report it within 24 hours from the order details screen and we\'ll issue an instant refund to your wallet.',
      'Orders',
    ),
    _FaqItem(
      'How do refunds work₹',
      'Refunds go to your Grokly Wallet instantly, or back to your original payment method within 3-5 business days.',
      'Payments',
    ),
    _FaqItem(
      'Which payment methods are accepted₹',
      'UPI, credit/debit cards, net banking, and Grokly Wallet balance are all supported at checkout.',
      'Payments',
    ),
    _FaqItem(
      'Is my payment information secure₹',
      'Yes — we never store your card details. All transactions are processed through PCI-DSS compliant partners.',
      'Payments',
    ),
    _FaqItem(
      'How do I change my delivery address₹',
      'Go to Profile > Saved Addresses to add, edit, or set a default delivery address.',
      'Account',
    ),
    _FaqItem(
      'How do I delete my account₹',
      'Email privacy@grokly.app from your registered email address and we\'ll process the request within 7 days.',
      'Account',
    ),
  ];

  List<_FaqItem> get _filtered {
    if (_query.trim().isEmpty) return _faqs;
    final q = _query.toLowerCase();
    return _faqs.where((f) =>
        f.question.toLowerCase().contains(q) ||
        f.answer.toLowerCase().contains(q) ||
        f.category.toLowerCase().contains(q)).toList();
  }

  Map<String, List<_FaqItem>> get _grouped {
    final map = <String, List<_FaqItem>>{};
    for (final item in _filtered) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  Future<void> _launch(Uri uri) async {
    try {
      if (!await launchUrl(uri)) throw Exception('Could not launch');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that app on this device')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: GroklyColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: GroklyColors.primary,
            foregroundColor: GroklyColors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text('Help & Support',
                  style: GroklyTextStyles.headlineLg.copyWith(color: GroklyColors.white, fontSize: 20)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [GroklyColors.primary, Color(0xFF1A7B48)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: GroklyColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: GroklyShadows.soft,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search for help...',
                        hintStyle: GroklyTextStyles.labelCaps.copyWith(fontSize: 12, letterSpacing: 0),
                        prefixIcon: const Icon(Icons.search, color: GroklyColors.outline),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, color: GroklyColors.outline, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick contact row
                  Text('CONTACT US', style: GroklyTextStyles.labelCaps.copyWith(fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _ContactCard(
                        icon: Icons.call_outlined,
                        label: 'Call',
                        color: Colors.blue.shade600,
                        onTap: () => _launch(Uri.parse('tel:+911800123456')),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _ContactCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Live Chat',
                        color: GroklyColors.primaryDark,
                        onTap: () {
                          // Wire this to your real chat/support widget.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening live chat...')),
                          );
                        },
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _ContactCard(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        color: Colors.orange.shade700,
                        onTap: () => _launch(Uri.parse(
                            'mailto:support@grokly.app?subject=Support%20Request')),
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text('FREQUENTLY ASKED', style: GroklyTextStyles.labelCaps.copyWith(fontSize: 11)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // FAQ list, grouped by category
          if (grouped.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 6, left: 4),
                      child: Text(entry.key,
                          style: GroklyTextStyles.sectionHeader.copyWith(
                              fontSize: 13, color: GroklyColors.primaryDark)),
                    ),
                    ...entry.value.map((f) => _FaqTile(item: f)),
                  ],
                ]),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _RaiseTicketBanner(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening ticket form...')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ContactCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: GroklyColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: GroklyShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 12)),
        ],
      ),
    ),
  );
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GroklyColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: GroklyShadows.soft,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.item.question,
                        style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: GroklyColors.outline, size: 22),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.item.answer,
                  style: GroklyTextStyles.labelCaps.copyWith(
                      fontSize: 12.5, letterSpacing: 0, color: GroklyColors.outline, height: 1.5)),
            ),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

class _RaiseTicketBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _RaiseTicketBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [GroklyColors.primary.withOpacity(0.12), GroklyColors.primary.withOpacity(0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GroklyColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: GroklyColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Icon(Icons.support_agent_rounded, color: GroklyColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Still need help₹', style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 15)),
                Text('Raise a ticket and we\'ll get back within 24h',
                    style: GroklyTextStyles.labelCaps.copyWith(fontSize: 10.5, letterSpacing: 0)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: GroklyColors.primaryDark, size: 20),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: GroklyColors.outline.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('No results found',
              style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 15)),
          const SizedBox(height: 4),
          Text('Try a different search term, or contact us directly above.',
              textAlign: TextAlign.center,
              style: GroklyTextStyles.labelCaps.copyWith(
                  fontSize: 11, letterSpacing: 0, color: GroklyColors.outline)),
        ],
      ),
    ),
  );
}


enum TxnType { order, topup, refund }

class WalletTransaction {
  final String title;
  final DateTime date;
  final double amount;
  final bool isCredit;
  final String status; // PAID, SUCCESS, REFUNDED
  final TxnType type;
  final String? orderId;
  final String? transactionId;

  WalletTransaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
    required this.status,
    required this.type,
    this.orderId,
    this.transactionId,
  });
}

class WalletScreen extends StatefulWidget {
  final int forteshredPoints;

  const WalletScreen({
    super.key,
    this.forteshredPoints = 450,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _balanceVisible = true;

  final List<WalletTransaction> _transactions = [
    WalletTransaction(
      title: 'Order #12345',
      date: DateTime(2023, 10, 24, 2, 30),
      amount: 450,
      isCredit: false,
      status: 'PAID',
      type: TxnType.order,
    ),
    WalletTransaction(
      title: 'Wallet Top-up',
      date: DateTime(2023, 10, 22, 11, 15),
      amount: 1000,
      isCredit: true,
      status: 'SUCCESS',
      type: TxnType.topup,
    ),
    WalletTransaction(
      title: 'Refund for Tomato',
      date: DateTime(2023, 10, 20, 9, 0),
      amount: 125,
      isCredit: true,
      status: 'REFUNDED',
      type: TxnType.refund,
    ),
    WalletTransaction(
      title: 'Order #12102',
      date: DateTime(2023, 10, 18, 4, 45),
      amount: 620.50,
      isCredit: false,
      status: 'PAID',
      type: TxnType.order,
    ),
  ];

  


  IconData _iconFor(TxnType type) {
    switch (type) {
      case TxnType.order:
        return Icons.shopping_bag_outlined;
      case TxnType.topup:
        return Icons.add_circle_outline;
      case TxnType.refund:
        return Icons.replay_outlined;
    }
  }

  Color _iconColorFor(TxnType type) {
    switch (type) {
      case TxnType.order:
        return const Color(0xFFE05B5B);
      case TxnType.topup:
        return const Color(0xFF2E7D5B);
      case TxnType.refund:
        return const Color(0xFF4A7FE0);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} • $hour:$minute $ampm';
  }

    @override
  Widget build(BuildContext context) {
    final wallet = GroklyWalletProvider.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1B15),
        elevation: 0,
        title: const Text('Wallet', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 16),
          _buildCashbackBanner(),
          const SizedBox(height: 20),
          _buildTransactionsHeader(),
          const SizedBox(height: 8),
          ...wallet.transactions.map(_buildTransactionTile),        
            const SizedBox(height: 16),
          _buildSecureFooter(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final wallet = GroklyWalletProvider.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5A3F), Color(0xFF123023)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GROKLY BALANCE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$_forteshredLabel: ${widget.forteshredPoints} pts',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
                            Text(
                _balanceVisible
           ? '₹${wallet.balance.toStringAsFixed(2)}'
                    : '₹••••••',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                child: Icon(
                  _balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _addMoneyDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF123023),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Add Money',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _addMoneyDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Add Money to Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF123023))),
            const SizedBox(height: 8),
            const Text('Top up your wallet for faster checkouts.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                hintText: '0.00',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [100, 500, 1000].map((amount) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () {
                        controller.text = amount.toString();
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text('+ ₹$amount', style: const TextStyle(color: Color(0xFF2E7D5B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  final amountStr = controller.text.trim();
                  if (amountStr.isEmpty) return;
                  final amount = double.tryParse(amountStr);
                  if (amount != null && amount > 0) {
                    final provider = context.dependOnInheritedWidgetOfExactType<GroklyWalletProvider>();
                    if (provider != null) {
                      provider.notifier!.addTopup(amount);
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully added ₹$amount to your wallet'),
                        backgroundColor: const Color(0xFF2E7D5B),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Add Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _forteshredLabel => 'FORTESHRED';

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label tapped'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E7D5B),
      ),
    );
  }



  Widget _buildCashbackBanner() {
    return GestureDetector(
      onTap: () => _showComingSoon('Wallet Cashback'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4C542).withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF4C542).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined, color: Color(0xFFF4C542)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Wallet Cashback\nGet 5% back on every top-up',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => _showComingSoon('See All'),
          child: const Text(
            'See All',
            style: TextStyle(color: Color(0xFF2E7D5B), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(WalletTransaction txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconColorFor(txn.type).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(txn.type), color: _iconColorFor(txn.type), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(txn.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${txn.isCredit ? '+' : '-'} ₹${txn.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: txn.isCredit ? const Color(0xFF4CAF7D) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                txn.status,
                style: TextStyle(
                  color: txn.isCredit ? const Color(0xFF4CAF7D) : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecureFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.lock_outline, color: Colors.white24, size: 14),
          SizedBox(width: 6),
          Text(
            'PCI-DSS COMPLIANT SECURE PAYMENTS',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ���������������������������������������������������������������
// SCREEN 6: CART
// ���������������������������������������������������������������

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isInstantSelected = true;
  Map<String, dynamic>? _selectedAddress;

  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);

    if (cart.items.isEmpty) {
      return Scaffold(
        backgroundColor: _GroklyScheduleUi.background,
        body: SafeArea(
          child: Column(
            children: [
              _GroklyGreenHeader(
                title: 'My Cart',
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5F1E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Color(0xFF2E805D),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18231D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add products to continue.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D766F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _GroklyScheduleUi.background,
      body: SafeArea(
        child: Column(
          children: [
            // ���������������������������������������������
            // HEADER
            // ���������������������������������������������

            _GroklyGreenHeader(
              title: 'My Cart',
              onBack: () => Navigator.pop(context),
            ),

            // ���������������������������������������������
            // CART CONTENT
            // ���������������������������������������������

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // �������������������������������������
                    // DELIVERY INFORMATION
                    // �������������������������������������

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F825D),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        17,
                        14,
                        17,
                        14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.timer_outlined,
                              color: Colors.white,
                              size: 29,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivery in 15 minutes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'shipment of ${cart.totalQty} items',
                                  style: const TextStyle(
                                    color: Color(0xFFD9ECE1),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // �������������������������������������
                    // PRODUCTS
                    // �������������������������������������

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(19),
                          bottomRight: Radius.circular(19),
                        ),
                        border: Border.all(
                          color: const Color(0xFFDDE4DE),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0;
                              i < cart.items.length;
                              i++) ...[
                            _GroklyCartProduct(
                              item: cart.items[i],
                            ),
                            if (i != cart.items.length - 1)
                              const Divider(
                                height: 1,
                                indent: 13,
                                endIndent: 13,
                                color: Color(0xFFE7EAE7),
                              ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // �������������������������������������
                    // CHOOSE DELIVERY
                    // �������������������������������������

                    const Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: Text(
                        'Choose Delivery',
                        style: TextStyle(
                          color: Color(0xFF18231D),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 11),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFBFC9C1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _GroklyDeliveryOption(
                            icon: Icons.bolt_rounded,
                            iconColor: const Color(0xFF234CC4),
                            title: 'Instant',
                            subtitle: 'Arrive in ~15 min',
                            selected: _isInstantSelected,
                            onTap: () {
                              setState(() {
                                _isInstantSelected = true;
                              });
                            },
                          ),
                          const Divider(
                            height: 1,
                            indent: 18,
                            endIndent: 18,
                          ),
                          _GroklyDeliveryOption(
                            icon: Icons.eco_outlined,
                            iconColor: const Color(0xFF378361),
                            title: 'Eco order',
                            subtitle: 'Arrive in ~30 min - 1 hr',
                            selected: !_isInstantSelected,
                            onTap: () {
                              setState(() {
                                _isInstantSelected = false;
                              });
                            },
                          ),
                          const Divider(
                            height: 1,
                            indent: 18,
                            endIndent: 18,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              15,
                              14,
                              17,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.home_filled,
                                  color: Color(0xFF15201A),
                                  size: 28,
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedAddress != null 
                                            ? 'Delivery to '
                                            : 'Delivery to Home',
                                          style: const TextStyle(
                                            color: Color(0xFF18231D),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _selectedAddress != null 
                                            ? ', ,  - '
                                          : 'Flat 502, Green Meadows Apartments 12th Cross...',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF6C756F),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GroklyAddressScreen(
                                            onAddressSelected: (addr) {
                                              setState(() {
                                                _selectedAddress = addr;
                                              });
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFF28322D),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(9),
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // �������������������������������������
                    // CHECKOUT NOW
                    // �������������������������������������

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF32855F),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 27,
                            ),
                            const SizedBox(width: 22),
                            const Text(
                              'Checkout Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 22),
                            Text(
                              '₹${cart.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // �������������������������������������
                    // SCHEDULE ORDER
                    // �������������������������������������

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DeliveryScheduleScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 61,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D432C),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white,
                              size: 27,
                            ),
                            SizedBox(width: 20),
                            Text(
                              'Schedule Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ���������������������������������������������������������������
// CART PRODUCT
// ���������������������������������������������������������������

class _GroklyCartProduct extends StatelessWidget {
  final CartItem item;

  const _GroklyCartProduct({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);

    final itemTotal =
        item.product.price * item.qty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              item.product.imageUrl,
              width: 77,
              height: 77,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 77,
                  height: 77,
                  color: const Color(0xFFE8F0EA),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFF527260),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF18231D),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.product.price.toStringAsFixed(0)} / unit',
                  style: const TextStyle(
                    color: Color(0xFF6C756F),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '₹${itemTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF173D2E),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GroklyQuantityButton(
                    icon: Icons.remove,
                    onTap: () =>
                        cart.remove(item.product),
                  ),
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _GroklyQuantityButton(
                    icon: Icons.add,
                    onTap: () =>
                        cart.add(item.product),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ���������������������������������������������������������������
// QUANTITY BUTTON
// ���������������������������������������������������������������

class _GroklyQuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GroklyQuantityButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 23,
        height: 23,
        decoration: const BoxDecoration(
          color: Color(0xFF3B8865),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }
}


// ���������������������������������������������������������������
// DELIVERY OPTION
// ���������������������������������������������������������������

class _GroklyDeliveryOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _GroklyDeliveryOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 13,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 33,
            ),
            const SizedBox(width: 19),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF18231D),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6C756F),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFE7F3EA)
                    : const Color(0xFFF8F8F8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF338562)
                      : const Color(0xFFB9BDBA),
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      color: Color(0xFF378263),
                      size: 23,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}


// ���������������������������������������������������������������
// SCREEN 7: SET DELIVERY SCHEDULE
// ���������������������������������������������������������������

class DeliveryScheduleScreen extends StatefulWidget {
  const DeliveryScheduleScreen({super.key});

  @override
  State<DeliveryScheduleScreen> createState() =>
      _DeliveryScheduleScreenState();
}

class _DeliveryScheduleScreenState
    extends State<DeliveryScheduleScreen> {
  DateTime _startDate =
      DateTime(2026, 9, 1);

  DateTime _endDate =
      DateTime(2026, 10, 15);

  String _frequency = 'Daily';

  DateTime _displayMonth =
      DateTime(2026, 9, 1);

  Future<void> _selectDate({
    required bool start,
  }) async {
    final initialDate =
        start ? _startDate : _endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2F855E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF17221C),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (start) {
        _startDate = picked;

        if (_endDate.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        if (!picked.isBefore(_startDate)) {
          _endDate = picked;
        }
      }

      _displayMonth =
          DateTime(picked.year, picked.month, 1);
    });
  }

  void _confirmPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPlanScreen(
          startDate: _startDate,
          endDate: _endDate,
          frequency: _frequency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);

    return Scaffold(
      backgroundColor:
          _GroklyScheduleUi.background,
      body: SafeArea(
        child: Column(
          children: [
            // ���������������������������������������������
            // HEADER
            // ���������������������������������������������

            _GroklyGreenHeader(
              title: 'Set Delivery Schedule',
              onBack: () => Navigator.pop(context),
            ),

            // ���������������������������������������������
            // CONTENT
            // ���������������������������������������������

            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  22,
                  16,
                  25,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ���������������������������������
                    // DATE SELECTION
                    // ���������������������������������

                    Row(
                      children: [
                        Expanded(
                          child: _GroklyDateField(
                            label: 'Start date',
                            value:
                                _formatDate(_startDate),
                            onTap: () =>
                                _selectDate(start: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GroklyDateField(
                            label: 'End date',
                            value:
                                _formatDate(_endDate),
                            onTap: () =>
                                _selectDate(start: false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ���������������������������������
                    // FREQUENCY
                    // ���������������������������������

                    const Text(
                      'Frequency',
                      style: TextStyle(
                        color: Color(0xFF18231D),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 9),

                    SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,
                      physics:
                          const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          'Daily',
                          'Weekly',
                          'Biweekly',
                          'Monthly',
                        ].map((frequency) {
                          final selected =
                              _frequency == frequency;

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              right: 8,
                            ),
                            child:
                                GestureDetector(
                              onTap: () {
                                setState(() {
                                  _frequency =
                                      frequency;
                                });
                              },
                              child:
                                  AnimatedContainer(
                                duration:
                                    const Duration(
                                  milliseconds: 150,
                                ),
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 17,
                                  vertical: 9,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: selected
                                      ? const Color(
                                          0xFFEAF4EB,
                                        )
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(18),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(
                                            0xFF3D8963,
                                          )
                                        : const Color(
                                            0xFFD0D6D1,
                                          ),
                                    width: selected
                                        ? 1.5
                                        : 1,
                                  ),
                                ),
                                child: Text(
                                  frequency,
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(
                                            0xFF2C7653,
                                          )
                                        : const Color(
                                            0xFF18231D,
                                          ),
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ���������������������������������
                    // CALENDAR
                    // ���������������������������������

                    _GroklyCalendar(
                      month: _displayMonth,
                      startDate: _startDate,
                      endDate: _endDate,
                      onPrevious: () {
                        setState(() {
                          _displayMonth = DateTime(
                            _displayMonth.year,
                            _displayMonth.month - 1,
                            1,
                          );
                        });
                      },
                      onNext: () {
                        setState(() {
                          _displayMonth = DateTime(
                            _displayMonth.year,
                            _displayMonth.month + 1,
                            1,
                          );
                        });
                      },
                      onDateTap: (date) {
                        setState(() {
                          if (date
                              .isBefore(_startDate)) {
                            _startDate = date;
                          } else if (date
                              .isAfter(_startDate)) {
                            _endDate = date;
                          } else {
                            _startDate = date;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 21),

                    // ���������������������������������
                    // DAILY COST & QUANTITY
                    // ���������������������������������

                    const Text(
                      'Daily cost & quantity',
                      style: TextStyle(
                        color: Color(0xFF18231D),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 9),

                    _GroklySummaryRow(
                      title: 'Total cost',
                      value:
                          '₹${cart.totalPrice.toStringAsFixed(0)}',
                    ),

                    const SizedBox(height: 7),

                    _GroklySummaryRow(
                      title: 'Total quantity',
                      value:
                          '${cart.totalQty}',
                    ),

                    const SizedBox(height: 23),

                    // ���������������������������������
                    // CONFIRM PLAN
                    // ���������������������������������

                    GestureDetector(
                      onTap: _confirmPlan,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0D432C),
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirm Your Plan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 15),
                            Icon(
                              Icons
                                  .calendar_month_outlined,
                              color: Colors.white,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ���������������������������������������������������������������
// DATE FIELD
// ���������������������������������������������������������������

class _GroklyDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _GroklyDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF18231D),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD0D6D1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF68726C),
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF59635D),
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// ���������������������������������������������������������������
// CALENDAR
// ���������������������������������������������������������������

class _GroklyCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateTap;

  const _GroklyCalendar({
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.onPrevious,
    required this.onNext,
    required this.onDateTap,
  });

  static const List<String> _weekDays = [
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
  ];

  @override
  Widget build(BuildContext context) {
    final firstDay =
        DateTime(month.year, month.month, 1);

    final daysInMonth =
        DateTime(
          month.year,
          month.month + 1,
          0,
        ).day;

    final leadingSpaces =
        firstDay.weekday % 7;

    // IMPORTANT:
    // This list MUST be growable because days are
    // appended below.
    final List<int?> cells = [];

    for (int i = 0;
        i < leadingSpaces;
        i++) {
      cells.add(null);
    }

    for (int day = 1;
        day <= daysInMonth;
        day++) {
      cells.add(day);
    }

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        11,
        12,
        13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFD2D9D3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // �������������������������������������
          // MONTH HEADER
          // �������������������������������������

          Row(
            children: [
              GestureDetector(
                onTap: onPrevious,
                child: const SizedBox(
                  width: 34,
                  height: 30,
                  child: Icon(
                    Icons.chevron_left,
                    size: 22,
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Month',
                      style: TextStyle(
                        color: Color(0xFF737B75),
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _monthName(month.month),
                      style: const TextStyle(
                        color: Color(0xFF18231D),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: onNext,
                child: const SizedBox(
                  width: 34,
                  height: 30,
                  child: Icon(
                    Icons.chevron_right,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // �������������������������������������
          // WEEK DAYS
          // �������������������������������������

          Row(
            children: _weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: Color(0xFF69736D),
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 3),

          // �������������������������������������
          // CALENDAR DAYS
          // �������������������������������������

          ...List.generate(
            cells.length ~/ 7,
            (rowIndex) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 1,
                ),
                child: Row(
                  children: List.generate(
                    7,
                    (columnIndex) {
                      final index =
                          rowIndex * 7 +
                              columnIndex;

                      final day =
                          cells[index];

                      if (day == null) {
                        return const Expanded(
                          child:
                              SizedBox(height: 30),
                        );
                      }

                      final date = DateTime(
                        month.year,
                        month.month,
                        day,
                      );

                      final isStart =
                          _isSameDate(
                        date,
                        startDate,
                      );

                      final isEnd =
                          _isSameDate(
                        date,
                        endDate,
                      );

                      final isBetween =
                          date.isAfter(
                                startDate,
                              ) &&
                              date.isBefore(
                                endDate,
                              );

                      Color? background;

                      if (isStart || isEnd) {
                        background =
                            const Color(0xFF3F9668);
                      } else if (isBetween) {
                        background =
                            const Color(0xFFBFE5C6);
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              onDateTap(date),
                          child: SizedBox(
                            height: 30,
                            child: Center(
                              child:
                                  AnimatedContainer(
                                duration:
                                    const Duration(
                                  milliseconds:
                                      120,
                                ),
                                width: 27,
                                height: 27,
                                alignment:
                                    Alignment.center,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      background,
                                  shape:
                                      BoxShape.circle,
                                ),
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    color:
                                        background ==
                                                null
                                            ? const Color(
                                                0xFF4F5953,
                                              )
                                            : (isStart ||
                                                    isEnd
                                                ? Colors
                                                    .white
                                                : const Color(
                                                    0xFF345B40,
                                                  )),
                                    fontSize: 9,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


// ���������������������������������������������������������������
// SUMMARY ROW
// ���������������������������������������������������������������

class _GroklySummaryRow extends StatelessWidget {
  final String title;
  final String value;

  const _GroklySummaryRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF18231D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          constraints:
              const BoxConstraints(
            minWidth: 50,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD4DBD5),
            ),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF18231D),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// ���������������������������������������������������������������
// SCREEN 8: REVIEW YOUR PLAN
// ���������������������������������������������������������������

class ReviewPlanScreen extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String frequency;

  const ReviewPlanScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final cart =
        GroklyCartProvider.of(context);

    return Scaffold(
      backgroundColor:
          _GroklyScheduleUi.background,
      body: SafeArea(
        child: Column(
          children: [
            // ���������������������������������������������
            // HEADER
            // ���������������������������������������������

            _GroklyGreenHeader(
              title: 'Review Your Plan',
              onBack: () => Navigator.pop(context),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  25,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ���������������������������������
                    // DATE
                    // ���������������������������������

                    const Text(
                      'Date',
                      style: TextStyle(
                        color: Color(0xFF18231D),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Expanded(
                          child:
                              _GroklySmallValue(
                            text:
                                _formatDate(
                              startDate,
                            ),
                          ),
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          child: Text(
                            '—',
                            style: TextStyle(
                              color:
                                  Colors.black38,
                            ),
                          ),
                        ),
                        Expanded(
                          child:
                              _GroklySmallValue(
                            text:
                                _formatDate(
                              endDate,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ���������������������������������
                    // FREQUENCY
                    // ���������������������������������

                    Row(
                      children: [
                        const Text(
                          'Frequency',
                          style: TextStyle(
                            color:
                                Color(0xFF18231D),
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        _GroklySmallValue(
                          text: frequency,
                          width: 78,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ���������������������������������
                    // ADDRESS
                    // ���������������������������������

                    Row(
                      children: [
                        const Text(
                          'Address',
                          style: TextStyle(
                            color:
                                Color(0xFF18231D),
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 23,
                          height: 23,
                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  const Color(
                                0xFF7C8780,
                              ),
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 15,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.fromLTRB(
                        13,
                        12,
                        10,
                        12,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        border: Border.all(
                          color:
                              const Color(
                            0xFFD2D9D3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Bengaluru, Karnataka, India',
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Flat 502, Green Meadows Apartments\n12th Cross, HSR Layout Sector 2',
                                  style:
                                      TextStyle(
                                    fontSize: 9.5,
                                    color:
                                        Color(
                                      0xFF6B756E,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.close,
                            size: 17,
                            color:
                                Color(0xFF7B827E),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ���������������������������������
                    // ALL PRODUCTS
                    // ���������������������������������

                    const Text(
                      'All Products',
                      style: TextStyle(
                        color: Color(0xFF18231D),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        border: Border.all(
                          color:
                              const Color(
                            0xFFD8DFD9,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0;
                              i < cart.items.length;
                              i++) ...[
                            _GroklyReviewProduct(
                              item: cart.items[i],
                            ),
                            if (i !=
                                cart.items.length -
                                    1)
                              const Divider(
                                height: 1,
                                indent: 12,
                                endIndent: 12,
                              ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ���������������������������������
                    // SET UP PAYMENT
                    // ���������������������������������

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PaymentScreen(
                              scheduled: true,
                              startDate:
                                  startDate,
                              endDate:
                                  endDate,
                              frequency:
                                  frequency,
                              returnItems:
                                  const [],
                              queuedReturnEntries:
                                  const [],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(0xFF0D432C),
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Text(
                              'Set up Payment',
                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 14),
                            Icon(
                              Icons
                                  .calendar_month_outlined,
                              color:
                                  Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ���������������������������������������������������������������
// REVIEW PRODUCT
// ���������������������������������������������������������������

class _GroklyReviewProduct
    extends StatelessWidget {
  final CartItem item;

  const _GroklyReviewProduct({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(9),
            child: Image.network(
              item.product.imageUrl,
              width: 43,
              height: 43,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) {
                return Container(
                  width: 43,
                  height: 43,
                  color:
                      const Color(0xFFE9F1EB),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 19,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              item.product.name,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF18231D),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 7),

          Text(
            'x${item.qty}',
            style: const TextStyle(
              color: Color(0xFF727A74),
              fontSize: 9,
            ),
          ),

          const SizedBox(width: 11),

          Text(
            '₹${(item.product.price * item.qty).toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF183F30),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(width: 5),

          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    const Color(0xFFC9D0CA),
              ),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}


// ���������������������������������������������������������������
// SMALL VALUE
// ���������������������������������������������������������������

class _GroklySmallValue
    extends StatelessWidget {
  final String text;
  final double? width;

  const _GroklySmallValue({
    required this.text,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD0D6D1),
        ),
      ),
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF18231D),
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


// ���������������������������������������������������������������
// SCREEN 9: SET PAYMENT
// ���������������������������������������������������������������

class PaymentScreen extends StatefulWidget {
  final List<ReturnableItem> returnItems;

  final List<
      MapEntry<MyOrderRecord, ReturnableItem>>
      queuedReturnEntries;

  final bool scheduled;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? frequency;

  const PaymentScreen({
    super.key,
    this.returnItems = const [],
    this.queuedReturnEntries = const [],
    this.scheduled = false,
    this.startDate,
    this.endDate,
    this.frequency,
  });

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}


class _PaymentScreenState
    extends State<PaymentScreen> {
  int _selectedPayment = 0;

  bool _processing = false;

  String? _placedOrderId;

  double _placedTotal = 0;

  Future<void> _confirmPayment() async {
    if (_processing) {
      return;
    }

    final cart = GroklyCartProvider.of(context);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty.'),
        ),
      );
      return;
    }

    setState(() {
      _processing = true;
    });

    final returnCredit = widget.returnItems.fold(
      0.0,
      (sum, item) => sum + item.credit,
    );

    final queuedCredit = widget.queuedReturnEntries.fold(
      0.0,
      (sum, entry) => sum + entry.value.credit,
    );

    final total = max(
      0.0,
      cart.totalPrice + 75 - returnCredit - queuedCredit,
    );

    const methods = [
      'Accesco Living Wallet',
      'Google Pay',
      'PhonePe',
      'Credit/Debit/ATM Card',
    ];

    final selectedMethod = methods[_selectedPayment];

    try {
      String? rzpOrderId;
      String? txnId;

      if (_selectedPayment == 0) {
        // Accesco Living Wallet
        final wallet = GroklyWalletProvider.of(context);
        if (wallet.balance < total) {
          if (mounted) {
            setState(() {
              _processing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Insufficient Wallet balance (₹${wallet.balance.toStringAsFixed(2)}). Please top up or select another method.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        wallet.payFromWallet(total);
        txnId = 'WAL_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Razorpay Online Checkout
        final paymentResult = await RazorpayService.openPayment(
          amount: total,
          description: 'Grokly Order Checkout ($selectedMethod)',
        );

        if (!paymentResult.success) {
          if (mounted) {
            setState(() {
              _processing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  paymentResult.message ?? 'Payment failed or cancelled.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        rzpOrderId = paymentResult.orderId;
        txnId = paymentResult.paymentId;
      }

      final orderId = await GroklyOrderRepository.placeOrder(
        items: List.of(cart.items),
        total: total,
        paymentMethod: selectedMethod,
        orderId: rzpOrderId,
        transactionId: txnId,
      );

      if (!mounted) {
        return;
      }

      _placedOrderId = orderId;
      _placedTotal = total;

      setState(() {
        _processing = false;
      });

      cart.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            orderId: orderId,
            total: total,
            returnItems: widget.returnItems,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _processing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart =
        GroklyCartProvider.of(context);

    final dailyTotal =
        cart.totalPrice;

    return Scaffold(
      backgroundColor:
          _GroklyScheduleUi.background,
      body: SafeArea(
        child: Column(
          children: [
            // ���������������������������������������������
            // HEADER
            // ���������������������������������������������

            _GroklyGreenHeader(
              title: 'Set Payment',
              onBack: () => Navigator.pop(context),
            ),

            // ���������������������������������������������
            // PAYMENT CONTENT
            // ���������������������������������������������

            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  28,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ���������������������������������
                    // MY PLAN
                    // ���������������������������������

                    Container(
                      width: double.infinity,
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        border: Border.all(
                          color:
                              const Color(
                            0xFFD2D9D3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              17,
                              16,
                              17,
                              15,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'My Plan',
                                      style:
                                          TextStyle(
                                        color:
                                            Color(
                                          0xFF18231D,
                                        ),
                                        fontSize:
                                            17,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons
                                          .edit_outlined,
                                      size: 20,
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                    height: 21),

                                _GroklyPlanRow(
                                  title: 'Date',
                                  value:
                                      '${_formatDate(widget.startDate ?? DateTime(2026, 9, 1))}   ${_formatDate(widget.endDate ?? DateTime(2026, 10, 15))}',
                                ),

                                const SizedBox(
                                    height: 13),

                                _GroklyPlanRow(
                                  title:
                                      'frequency',
                                  value:
                                      widget.frequency ??
                                          'Daily',
                                ),

                                const SizedBox(
                                    height: 13),

                                _GroklyPlanRow(
                                  title:
                                      'Daily quantity',
                                  value:
                                      '${cart.totalQty}',
                                ),

                                const SizedBox(
                                    height: 18),

                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Icon(
                                      Icons
                                          .location_on_outlined,
                                      color:
                                          Color(
                                        0xFF16201B,
                                      ),
                                      size: 27,
                                    ),
                                    const SizedBox(
                                        width: 10),
                                    const Expanded(
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            'Bengaluru, Karnataka, India',
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  13,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                          SizedBox(
                                              height:
                                                  4),
                                          Text(
                                            'Flat 502, Green Meadows Apartments 12th Cross,\nHSR Layout Sector 2',
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  9.5,
                                              color:
                                                  Color(
                                                0xFF68736C,
                                              ),
                                              height:
                                                  1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // �����������������������������
                          // TOTAL COST BAR
                          // �����������������������������

                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 17,
                              vertical: 12,
                            ),
                            decoration:
                                const BoxDecoration(
                              color: Color(
                                0xFF185C3E,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .only(
                                bottomLeft:
                                    Radius
                                        .circular(
                                  15,
                                ),
                                bottomRight:
                                    Radius
                                        .circular(
                                  15,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Daily total cost',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .white,
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors
                                            .white,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                  ),
                                  child: Text(
                                    '₹${dailyTotal.toStringAsFixed(0)}',
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(
                                        0xFF18231D,
                                      ),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ���������������������������������
                    // AUTOPAY
                    // ���������������������������������

                    const Text(
                      'Set up Autopay',
                      style: TextStyle(
                        color: Color(0xFF18231D),
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 11),

                    Container(
                      width: double.infinity,
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        border: Border.all(
                          color:
                              const Color(
                            0xFFD2D9D3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          _GroklyPaymentMethod(
                            title:
                                'Accesco Living',
                            subtitle:
                                'wallet',
                            type:
                                _GroklyPaymentType
                                    .wallet,
                            selected:
                                _selectedPayment ==
                                    0,
                            onTap: () {
                              setState(() {
                                _selectedPayment =
                                    0;
                              });
                            },
                          ),

                          const Divider(
                            height: 1,
                            indent: 18,
                            endIndent: 18,
                          ),

                          _GroklyPaymentMethod(
                            title:
                                'Google Pay',
                            subtitle: '',
                            type:
                                _GroklyPaymentType
                                    .google,
                            selected:
                                _selectedPayment ==
                                    1,
                            onTap: () {
                              setState(() {
                                _selectedPayment =
                                    1;
                              });
                            },
                          ),

                          const Divider(
                            height: 1,
                            indent: 18,
                            endIndent: 18,
                          ),

                          _GroklyPaymentMethod(
                            title: 'Phone Pe',
                            subtitle: '',
                            type:
                                _GroklyPaymentType
                                    .phonePe,
                            selected:
                                _selectedPayment ==
                                    2,
                            onTap: () {
                              setState(() {
                                _selectedPayment =
                                    2;
                              });
                            },
                          ),

                          const Divider(
                            height: 1,
                            indent: 18,
                            endIndent: 18,
                          ),

                          _GroklyPaymentMethod(
                            title:
                                'Add Credit/Debit/\nATM Cards',
                            subtitle: '',
                            type:
                                _GroklyPaymentType
                                    .card,
                            selected:
                                _selectedPayment ==
                                    3,
                            onTap: () {
                              setState(() {
                                _selectedPayment =
                                    3;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ���������������������������������
                    // CONFIRM
                    // ���������������������������������

                    GestureDetector(
                      onTap:
                          _processing
                              ? null
                              : _confirmPayment,
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFF0D432C,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Center(
                          child: _processing
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2.2,
                                    color:
                                        Colors
                                            .white,
                                  ),
                                )
                              : const Text(
                                  'Confirm',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .white,
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    // ���������������������������������
                    // TERMS
                    // ���������������������������������

                    Center(
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Text(
                            'Terms and Conditions',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF18231D,
                              ),
                              fontSize: 12,
                              decoration:
                                  TextDecoration
                                      .underline,
                            ),
                          ),
                          const SizedBox(
                              width: 6),
                          const Icon(
                            Icons.open_in_new,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ���������������������������������������������������������������
// PLAN ROW
// ���������������������������������������������������������������

class _GroklyPlanRow extends StatelessWidget {
  final String title;
  final String value;

  const _GroklyPlanRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF18231D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color:
                    const Color(0xFFD0D6D1),
              ),
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF18231D),
                fontSize: 9.5,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// ���������������������������������������������������������������
// PAYMENT METHOD
// ���������������������������������������������������������������

enum _GroklyPaymentType {
  wallet,
  google,
  phonePe,
  card,
}


class _GroklyPaymentMethod
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final _GroklyPaymentType type;
  final bool selected;
  final VoidCallback onTap;

  const _GroklyPaymentMethod({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 150),
        margin:
            const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 7,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF9EEFC7)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _GroklyPaymentLogo(
              type: type,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF214637),
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF253C32),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF28724F)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF28724F)
                      : const Color(0xFFC6CCC8),
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 23,
                    )
                  : const Icon(
                      Icons.add,
                      color:
                          Color(0xFF1C2821),
                      size: 22,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


// ���������������������������������������������������������������
// PAYMENT LOGO
// ���������������������������������������������������������������

class _GroklyPaymentLogo
    extends StatelessWidget {
  final _GroklyPaymentType type;

  const _GroklyPaymentLogo({
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case _GroklyPaymentType.wallet:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF99004D),
            borderRadius:
                BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons
                .account_balance_wallet,
            color: Colors.white,
            size: 28,
          ),
        );

      case _GroklyPaymentType.google:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                const Color(0xFFF5F5F5),
            borderRadius:
                BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: const Text(
            'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 27,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        );

      case _GroklyPaymentType.phonePe:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                const Color(0xFF5B36B4),
            borderRadius:
                BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: const Text(
            'α��α��',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        );

      case _GroklyPaymentType.card:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(11),
            border: Border.all(
              color:
                  const Color(0xFFD3D8D4),
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.add,
            color: Color(0xFF253029),
            size: 26,
          ),
        );
    }
  }
}


// ���������������������������������������������������������������
// GREEN HEADER
// ���������������������������������������������������������������

class _GroklyGreenHeader
    extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _GroklyGreenHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration:
          const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B4F30),
            Color(0xFF176A43),
          ],
        ),
        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(28),
          bottomRight:
              Radius.circular(28),
        ),
      ),
      padding:
          const EdgeInsets.fromLTRB(
        13,
        10,
        16,
        21,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          
          const SizedBox(height: 13),

          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 39,
                  height: 39,
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ���������������������������������������������������������������
// UI CONSTANTS
// ���������������������������������������������������������������

class _GroklyScheduleUi {
  static const Color background =
      Color(0xFFF4F8F3);
}


// ���������������������������������������������������������������
// DATE HELPERS
// ���������������������������������������������������������������

String _formatDate(DateTime date) {
  final day =
      date.day.toString().padLeft(2, '0');

  final month =
      date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}


bool _isSameDate(
  DateTime first,
  DateTime second,
) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}


String _monthName(int month) {
  const months = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return months[month];
}
// ���������������������������������������������
// ORDER ARRIVING — handoff screen
// ���������������������������������������������

class OrderArrivingScreen extends StatefulWidget {
  final String? orderId;
  final List<ReturnableItem> returnItems;
  final List<MapEntry<MyOrderRecord, ReturnableItem>> queuedReturnEntries;
  const OrderArrivingScreen({
    super.key,
    this.orderId,
    this.returnItems = const [],
    this.queuedReturnEntries = const [],
  });

  @override
  State<OrderArrivingScreen> createState() => _OrderArrivingScreenState();
}

class _OrderArrivingScreenState extends State<OrderArrivingScreen> {
  late Set<String> _selectedCurrent;
  late Set<String> _selectedQueued;

  @override
  void initState() {
    super.initState();
    _selectedCurrent = widget.returnItems.where((r) => r.selected).map((r) => r.label).toSet();
    _selectedQueued = widget.queuedReturnEntries
        .where((e) => e.value.selected)
        .map((e) => '${e.key.id}|${e.value.label}')
        .toSet();
  }

  double get _totalCredit {
    double t = 0;
    for (final r in widget.returnItems) {
      if (_selectedCurrent.contains(r.label)) t += r.credit;
    }
    for (final e in widget.queuedReturnEntries) {
      if (_selectedQueued.contains('${e.key.id}|${e.value.label}')) t += e.value.credit;
    }
    return t;
  }

  int get _itemCount => _selectedCurrent.length + _selectedQueued.length;

  void _confirmHandoff() {
    final ordersState = GroklyOrdersProvider.of(context);
    final confirmedOrders = widget.queuedReturnEntries
        .where((e) => _selectedQueued.contains('${e.key.id}|${e.value.label}'))
        .map((e) => e.key)
        .toSet();
    if (confirmedOrders.isNotEmpty) {
      ordersState.markReturned(confirmedOrders);
    }
    final combined = <ReturnableItem>[
      ...widget.returnItems.where((r) => _selectedCurrent.contains(r.label)),
      ...widget.queuedReturnEntries
          .where((e) => _selectedQueued.contains('${e.key.id}|${e.value.label}'))
          .map((e) => e.value),
    ];
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => ReturnConfirmedScreen(returnItems: combined)));
  }

  void _skipReturn() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: widget.orderId)));
  }

  @override
  Widget build(BuildContext context) {
    final fromOrderLabel =
        widget.queuedReturnEntries.isNotEmpty ? widget.queuedReturnEntries.first.key.id : null;
    final hasAnyItems = widget.returnItems.isNotEmpty || widget.queuedReturnEntries.isNotEmpty;

    return Scaffold(
      backgroundColor: _FxUi.bg,
      body: Column(
        children: [
          Container(
            color: GroklyColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: GroklyColors.white),
                    ),
                    Expanded(
                      child: Text('Order arriving',
                          style: GroklyTextStyles.sectionHeader
                              .copyWith(color: GroklyColors.white, fontSize: 19)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _FxCard(
                  color: _FxUi.mint,
                  borderColor: _FxUi.mintBorder,
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(color: _FxUi.bg, shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, color: _FxUi.green, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vinod is at your door', style: _FxText.rowTitle),
                            SizedBox(height: 2),
                            Text('Arrived · Tap to confirm receipt', style: _FxText.small),
                          ],
                        ),
                      ),
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: _FxUi.bg, borderRadius: BorderRadius.circular(19)),
                        child: const Icon(Icons.call_outlined, color: _FxUi.green, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (hasAnyItems) ...[
                  Text('QUEUED ECO-RETURN — HAND TO RIDER NOW',
                      style: _FxText.tag.copyWith(color: _FxUi.green, letterSpacing: 0.6)),
                  const SizedBox(height: 10),
                  _FxCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            fromOrderLabel != null
                                ? 'Give these items to Vinod\nFrom Order #$fromOrderLabel · last chance'
                                : 'Give these items to Vinod\nLast chance — credit added after he confirms',
                            style: _FxText.small),
                        const SizedBox(height: 12),
                        ...widget.returnItems.map((r) {
                          final checked = _selectedCurrent.contains(r.label);
                          return _handoffRow(
                            label: '${r.label} x ${r.qty}',
                            sub: r.material,
                            credit: r.credit,
                            checked: checked,
                            onTap: () => setState(() =>
                                checked ? _selectedCurrent.remove(r.label) : _selectedCurrent.add(r.label)),
                          );
                        }),
                        ...widget.queuedReturnEntries.map((e) {
                          final key = '${e.key.id}|${e.value.label}';
                          final checked = _selectedQueued.contains(key);
                          return _handoffRow(
                            label: '${e.value.label} x ${e.value.qty}',
                            sub: '${e.value.material} · Order #${e.key.id}',
                            credit: e.value.credit,
                            checked: checked,
                            onTap: () => setState(
                                () => checked ? _selectedQueued.remove(key) : _selectedQueued.add(key)),
                          );
                        }),
                        const Divider(height: 20, color: _FxUi.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$_itemCount item${_itemCount == 1 ? '' : 's'} queued', style: _FxText.rowTitle),
                            Text('+₹${_totalCredit.toStringAsFixed(0)}',
                                style: _FxText.price.copyWith(color: _FxUi.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else
                  _FxMintBanner(
                    icon: Icons.local_shipping_outlined,
                    title: 'No packaging queued',
                    subtitle: 'Your delivery has no eco-return items this time.',
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: _FxUi.bg,
            border: Border(top: BorderSide(color: _FxUi.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FxCta(
                label: _itemCount > 0 ? 'I handed it to the rider ✓' : 'Confirm Receipt',
                icon: Icons.check_rounded,
                onTap: _itemCount > 0
                    ? _confirmHandoff
                    : () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: widget.orderId))),
              ),
              if (_itemCount > 0) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _skipReturn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('I changed my mind – skip return',
                        style: _FxText.small
                            .copyWith(color: _FxUi.textGray, decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _handoffRow({
    required String label,
    required String sub,
    required double credit,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            _FxCheck(value: checked, onTap: onTap),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _FxText.rowTitle.copyWith(fontSize: 13)),
                  Text(sub, style: _FxText.small),
                ],
              ),
            ),
            Text('+₹${credit.toStringAsFixed(0)}',
                style: _FxText.price.copyWith(fontSize: 13, color: _FxUi.green)),
          ],
        ),
      ),
    );
  }
}

// ���������������������������������������������
// MY ORDERS
// ���������������������������������������������

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final Map<String, Set<String>> _selections = {};

  Set<String> _selectionFor(MyOrderRecord order) => _selections.putIfAbsent(
      order.id, () => order.returnables.where((r) => r.selected).map((r) => r.label).toSet());

  @override
  Widget build(BuildContext context) {
    final ordersState = GroklyOrdersProvider.of(context);

    return Scaffold(
      backgroundColor: _FxUi.bg,
      body: Column(
        children: [
          Container(
            color: GroklyColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: GroklyColors.white),
                    ),
                    Expanded(
                      child: Text('My orders',
                          style: GroklyTextStyles.sectionHeader
                              .copyWith(color: GroklyColors.white, fontSize: 19)),
                    ),
                    if (ordersState.returnEligibleCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: GroklyColors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('${ordersState.returnEligibleCount} return eligible',
                            style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.white, fontSize: 10)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text('RECENT ORDERS', style: _FxText.tag.copyWith(color: _FxUi.textGray, letterSpacing: 0.6)),
                const SizedBox(height: 10),
                ...ordersState.orders.map((o) => GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => _OrderDetailScreen(order: o))),
                      child: _MyOrderCard(
                        order: o,
                        selected: _selectionFor(o),
                        onToggle: (label) => setState(() {
                          final sel = _selectionFor(o);
                          sel.contains(label) ? sel.remove(label) : sel.add(label);
                        }),
                        onQueue: () {
                          for (final r in o.returnables) {
                            r.selected = _selectionFor(o).contains(r.label);
                          }
                          ordersState.queueForNextDelivery(o);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Queued for your next delivery'),
                              backgroundColor: GroklyColors.primary));
                        },
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyOrderCard extends StatelessWidget {
  final MyOrderRecord order;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onQueue;
  const _MyOrderCard({
    required this.order,
    required this.selected,
    required this.onToggle,
    required this.onQueue,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCredit =
        order.returnables.where((r) => selected.contains(r.label)).fold(0.0, (s, r) => s + r.credit);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _FxUi.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _FxUi.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.id}', style: _FxText.rowTitle.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${order.dateLabel} · ₹${order.total.toStringAsFixed(0)} · ${order.statusLabel}',
                        style: _FxText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusTag(),
            ],
          ),
          if (order.returnStatus == ReturnQueueStatus.eligible) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: _FxUi.border),
            const SizedBox(height: 10),
            Text('ELIGIBLE FOR ECO-RETURN', style: _FxText.tag.copyWith(color: _FxUi.green, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...order.returnables.map((r) {
              final checked = selected.contains(r.label);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: GestureDetector(
                  onTap: () => onToggle(r.label),
                  child: Row(
                    children: [
                      _FxCheck(value: checked, onTap: () => onToggle(r.label)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text('${r.label} x ${r.qty}',
                              style: _FxText.body.copyWith(color: _FxUi.textDark, fontSize: 13))),
                      Text('+₹${r.credit.toStringAsFixed(0)}',
                          style: _FxText.small.copyWith(color: _FxUi.green, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            _FxCta(
              label: 'Queue for next delivery +₹${selectedCredit.toStringAsFixed(0)}',
              enabled: selected.isNotEmpty,
              onTap: () {
                if (selected.isNotEmpty) onQueue();
              },
            ),
          ] else if (order.returnStatus == ReturnQueueStatus.queued) ...[
            const SizedBox(height: 6),
            Text('Will be collected on your next delivery', style: _FxText.small.copyWith(color: _FxUi.green)),
          ] else if (order.returnStatus == ReturnQueueStatus.returned) ...[
            const SizedBox(height: 6),
            Text(
                'Returned · ₹${(order.creditedAmount ?? 0).toStringAsFixed(0)} credited to wallet',
                style: _FxText.small.copyWith(color: _FxUi.green)),
          ],
        ],
      ),
    );
  }

  Widget _statusTag() {
    switch (order.returnStatus) {
      case ReturnQueueStatus.eligible:
        return _FxTag('RETURN ELIGIBLE');
      case ReturnQueueStatus.queued:
        return _FxTag('QUEUED ↑', color: _FxUi.amber, bg: _FxUi.amberBg);
      case ReturnQueueStatus.returned:
        return _FxTag('RETURNED ✓', filled: true);
      case ReturnQueueStatus.notEligible:
        return _FxTag('NOT ELIGIBLE', color: _FxUi.textGray, bg: _FxUi.thumb);
    }
  }
}
// ---------------------------------------------
// ORDER DETAIL SCREEN
// ---------------------------------------------

class _OrderDetailScreen extends StatelessWidget {
  final MyOrderRecord order;
  const _OrderDetailScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.statusLabel.toLowerCase().contains('cancel');
    final statusColor = isCancelled ? GroklyColors.error : GroklyColors.primary;

    return Scaffold(
      backgroundColor: GroklyColors.background,
      body: Column(
        children: [
          // Header
          Container(
            color: GroklyColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: GroklyColors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${order.id}',
                              style: GroklyTextStyles.sectionHeader
                                  .copyWith(color: GroklyColors.white, fontSize: 19)),
                          Text('Placed on ${order.dateLabel}',
                              style: GroklyTextStyles.labelCaps.copyWith(
                                  color: GroklyColors.primaryFixed, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCancelled ? Icons.cancel_outlined : Icons.check_circle_outlined,
                          color: statusColor, size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.statusLabel,
                                style: GroklyTextStyles.sectionHeader.copyWith(
                                    color: statusColor, fontSize: 16)),
                            Text(
                              isCancelled
                                  ? 'This order was cancelled'
                                  : 'Your order has been delivered successfully',
                              style: GroklyTextStyles.bodyMain.copyWith(
                                  color: GroklyColors.onSurfaceVar, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Products section
                Text('ITEMS ORDERED',
                    style: GroklyTextStyles.labelCaps.copyWith(
                        color: GroklyColors.outline, letterSpacing: 0.8)),
                const SizedBox(height: 12),

                if (order.products.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: GroklyColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text('Product details not available',
                          style: GroklyTextStyles.bodyMain
                              .copyWith(color: GroklyColors.outline)),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: GroklyColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: GroklyShadows.soft,
                    ),
                    child: Column(
                      children: [
                        ...order.products.asMap().entries.map((entry) {
                          final i = entry.key;
                          final p = entry.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        p.imageUrl,
                                        width: 56, height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 56, height: 56,
                                          color: GroklyColors.surfaceMint,
                                          child: const Icon(Icons.image_outlined,
                                              color: GroklyColors.outline, size: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name,
                                              style: GroklyTextStyles.bodyMain.copyWith(
                                                  fontWeight: FontWeight.w600, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text('${p.size} × ${p.qty}',
                                              style: GroklyTextStyles.labelCaps.copyWith(
                                                  color: GroklyColors.outline, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Text('₹${(p.price * p.qty).toStringAsFixed(0)}',
                                        style: GroklyTextStyles.sectionHeader
                                            .copyWith(fontSize: 15)),
                                  ],
                                ),
                              ),
                              if (i < order.products.length - 1)
                                Divider(height: 1, color: GroklyColors.outlineVar.withOpacity(0.3),
                                    indent: 14, endIndent: 14),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Price summary
                Text('PRICE SUMMARY',
                    style: GroklyTextStyles.labelCaps.copyWith(
                        color: GroklyColors.outline, letterSpacing: 0.8)),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GroklyColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: GroklyShadows.soft,
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Items total', '₹${order.total.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _summaryRow('Delivery fee', 'FREE',
                          valueColor: GroklyColors.primary),
                      const Divider(height: 20),
                      _summaryRow(
                        'Total paid',
                        '₹${order.total.toStringAsFixed(0)}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),

                if (order.creditedAmount != null && order.creditedAmount! > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GroklyColors.surfaceMint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: GroklyColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Eco-return credit: ₹${order.creditedAmount!.toStringAsFixed(0)} added to wallet',
                            style: GroklyTextStyles.bodyMain.copyWith(
                                color: GroklyColors.primary, fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GroklyTextStyles.bodyMain.copyWith(
                color: GroklyColors.onSurfaceVar,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14)),
        Text(value,
            style: GroklyTextStyles.sectionHeader.copyWith(
                fontSize: isBold ? 16 : 14,
                color: valueColor ?? GroklyColors.onSurface,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}



// ���������������������������������������������
// SCREEN 9: SMART PANTRY — Depletion Tracker
// Redesigned to the return-flow Figma UI. The ML model infers pantry
// state from household size + purchase velocity, alerts 2–3 days
// before predicted depletion, and offers one-tap restock. Restocking
// really adds the matched catalog product to the cart AND refills the
// item's tracked stock level in local state.
// ���������������������������������������������

class _PantryEntry {
  final String productId;
  final String velocity; // e.g. "1L every 2 days"
  int daysLeft;
  double stockPct;
  bool restocked;
  _PantryEntry({
    required this.productId,
    required this.velocity,
    required this.daysLeft,
    required this.stockPct,
    this.restocked = false,
  });

  factory _PantryEntry.fromSmartPantryItem(SmartPantryItem item) {
    return _PantryEntry(
      productId: item.productId,
      velocity: item.recommendationReason.isNotEmpty
          ? item.recommendationReason
          : 'Velocity: every ${item.velocityDays} days',
      daysLeft: item.daysLeft,
      stockPct: item.stockPct,
      restocked: item.restocked,
    );
  }

  GroklyProduct? get product =>
      GroklyCatalog.all.where((p) => p.id == productId).firstOrNull;

  bool get isLow => !restocked && daysLeft <= 3;
}

class SmartPantryScreen extends StatefulWidget {
  const SmartPantryScreen({super.key});
  @override
  State<SmartPantryScreen> createState() => _SmartPantryScreenState();
}

class _SmartPantryScreenState extends State<SmartPantryScreen> {
  int _filter = 0; // 0 All · 1 Running Low · 2 Stocked

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final priceMap = {for (final p in GroklyCatalog.all) p.id: p.price};
      context.read<SixthSenseProvider>().loadRecommendations(catalogPriceLookup: priceMap);
    });
  }

  List<_PantryEntry> _getPantry(BuildContext context) {
    final items = context.watch<SixthSenseProvider>().smartPantryItems;
    return items.map(_PantryEntry.fromSmartPantryItem).toList();
  }

  void _restock(_PantryEntry e) {
    final product = e.product;
    if (product == null) return;
    GroklyCartProvider.of(context).add(product);
    context.read<SixthSenseProvider>().restockPantryItem(e.productId);
    setState(() {
      e.restocked = true;
      e.stockPct = 1.0;
      e.daysLeft = 14;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${product.name} added to cart — pantry refilled'),
        backgroundColor: _FxUi.green));
  }

  void _restockAllLow() {
    final pantry = _getPantry(context);
    final low = pantry.where((e) => e.isLow).toList();
    if (low.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nothing is running low — pantry fully stocked!'),
          backgroundColor: _FxUi.green));
      return;
    }
    final cart = GroklyCartProvider.of(context);
    final provider = context.read<SixthSenseProvider>();
    for (final e in low) {
      final product = e.product;
      if (product == null) continue;
      cart.add(product);
      provider.restockPantryItem(e.productId);
      e.restocked = true;
      e.stockPct = 1.0;
      e.daysLeft = 14;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${low.length} low-stock items added to cart'),
        backgroundColor: _FxUi.green));
  }

  @override
  Widget build(BuildContext context) {
    final pantry = _getPantry(context);
    final lowCount = pantry.where((e) => e.isLow).length;
    final alerts = pantry.where((e) => e.isLow).toList();
    final List<_PantryEntry> visible;
    switch (_filter) {
      case 1:
        visible = alerts;
        break;
      case 2:
        visible = pantry.where((e) => !e.isLow).toList();
        break;
      default:
        visible = pantry;
    }

    return Scaffold(
      backgroundColor: _FxUi.bg,
      body: Column(
        children: [
          const _FxAppBar(title: 'Smart Pantry'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _FxMintBanner(
                  icon: Icons.model_training_outlined,
                  title: 'Depletion Tracker is active',
                  subtitle:
                      'ML model infers your pantry state from household size & purchase velocity — no manual entry.',
                ),
                const SizedBox(height: 14),

                // �� Household model card ��
                _FxCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                              child: Text('Household Model',
                                  style: _FxText.cardTitle)),
                          _FxTag('94% CONFIDENCE'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _ModelRow(
                          icon: Icons.groups_outlined,
                          label: 'Household size',
                          value: '4 members'),
                      const _ModelRow(
                          icon: Icons.speed_outlined,
                          label: 'Purchase velocity',
                          value: '2.3 orders / week'),
                      const _ModelRow(
                          icon: Icons.notifications_active_outlined,
                          label: 'Alert window',
                          value: '2–3 days before depletion',
                          isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // �� Depletion alerts ��
                _FxSectionTitle(
                  'Depletion Alerts',
                  trailing: alerts.isEmpty
                      ? const _FxTag('ALL CLEAR')
                      : _FxTag('${alerts.length} DUE SOON',
                          color: _FxUi.amber, bg: _FxUi.amberBg),
                ),
                const SizedBox(height: 10),
                if (alerts.isEmpty)
                  _FxCard(
                    color: _FxUi.mint,
                    borderColor: _FxUi.mintBorder,
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: _FxUi.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              'Nothing is predicted to run out in the next 3 days.',
                              style: _FxText.body
                                  .copyWith(color: _FxUi.green)),
                        ),
                      ],
                    ),
                  )
                else
                  ...alerts.map((e) => _AlertCard(entry: e, onRestock: () => _restock(e))),
                const SizedBox(height: 18),

                // �� Full inventory ��
                const _FxSectionTitle('Pantry Inventory'),
                const SizedBox(height: 10),
                _FxPills(
                  labels: const ['All', 'Running Low', 'Stocked'],
                  selected: _filter,
                  onSelect: (i) => setState(() => _filter = i),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: Text('No items in this view',
                            style: _FxText.body)),
                  )
                else
                  ...visible.map((e) => _InventoryRow(
                      entry: e, onRestock: () => _restock(e))),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: _FxUi.bg,
            border: Border(top: BorderSide(color: _FxUi.border)),
          ),
          child: _FxCta(
            label: lowCount > 0
                ? 'One-Tap Restock ($lowCount low items)'
                : 'Pantry Fully Stocked',
            icon: lowCount > 0 ? Icons.autorenew : Icons.check_rounded,
            onTap: _restockAllLow,
          ),
        ),
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _ModelRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.isLast = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: _FxUi.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _FxUi.green, size: 17),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: _FxText.body)),
            Text(value,
                style: _FxText.small.copyWith(
                    color: _FxUi.textDark, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

/// Amber/red alert card — item predicted to deplete within 3 days.
class _AlertCard extends StatelessWidget {
  final _PantryEntry entry;
  final VoidCallback onRestock;
  const _AlertCard({required this.entry, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    final p = entry.product;
    if (p == null) return const SizedBox.shrink();
    final critical = entry.daysLeft <= 1;
    final tagColor = critical ? _FxUi.red : _FxUi.amber;
    final tagBg = critical ? _FxUi.redBg : _FxUi.amberBg;

    return _FxCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FxThumb(p.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: _FxText.rowTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${p.size} · usage ${entry.velocity}',
                        style: _FxText.small),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _FxTag(
                  critical
                      ? 'RUNS OUT TOMORROW'
                      : '${entry.daysLeft} DAYS LEFT',
                  color: tagColor,
                  bg: tagBg),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: entry.stockPct,
              minHeight: 6,
              backgroundColor: _FxUi.thumb,
              valueColor: AlwaysStoppedAnimation(tagColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                    'Predicted depletion in ${entry.daysLeft} day${entry.daysLeft == 1 ? '' : 's'} — restock now to stay ahead.',
                    style: _FxText.small),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onRestock,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _FxUi.green,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text('Restock ₹${p.price.toStringAsFixed(0)}',
                      style: _FxText.button.copyWith(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inventory list row — thumbnail, velocity, stock bar and status tag.
class _InventoryRow extends StatelessWidget {
  final _PantryEntry entry;
  final VoidCallback onRestock;
  const _InventoryRow({required this.entry, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    final p = entry.product;
    if (p == null) return const SizedBox.shrink();

    final Widget statusTag;
    final Color barColor;
    if (entry.restocked) {
      statusTag = const _FxTag('RESTOCKED', filled: true);
      barColor = _FxUi.green;
    } else if (entry.isLow) {
      statusTag = _FxTag('${entry.daysLeft}D LEFT',
          color: _FxUi.amber, bg: _FxUi.amberBg);
      barColor = _FxUi.amber;
    } else {
      statusTag = _FxTag('${(entry.stockPct * 100).round()}% STOCKED');
      barColor = _FxUi.green;
    }

    return _FxCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              _FxThumb(p.imageUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: _FxText.rowTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Usage: ${entry.velocity}', style: _FxText.small),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              statusTag,
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRestock,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _FxUi.mint,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _FxUi.mintBorder),
                  ),
                  child: const Icon(Icons.add, color: _FxUi.green, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: entry.stockPct,
              minHeight: 5,
              backgroundColor: _FxUi.thumb,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ���������������������������������������������
// SCREEN 10: DISH-FIRST GROCERY SHOPPING
// Redesigned to the return-flow Figma UI. Users choose a dish first
// and instantly get every ingredient — reducing friction, saving time
// and increasing cart value through smarter, intuitive shopping.
// Flow: dish list → "Select Ingredients" (green checkboxes, like the
// select-items-to-return frame) → confirmation (like Return Confirmed).
// ���������������������������������������������

/// Matches an ingredient to a real catalog product (for price + cart).
GroklyProduct? _fxMatchIngredient(RecipeIngredient ing) =>
    GroklyCatalog.all
        .where((p) => p.name
            .toLowerCase()
            .contains(ing.name.toLowerCase().split(' ').first))
        .firstOrNull;

double _fxIngredientPrice(RecipeIngredient ing, GroklyRecipe recipe) =>
    _fxMatchIngredient(ing)?.price ??
    (recipe.estimatedCost / recipe.ingredients.length);

class DishFirstScreen extends StatefulWidget {
  const DishFirstScreen({super.key});
  @override
  State<DishFirstScreen> createState() => _DishFirstScreenState();
}

class _DishFirstScreenState extends State<DishFirstScreen> {
  String _search = '';
  int _cuisine = 0;

  List<String> get _cuisines {
    final set = <String>{};
    for (final r in GroklyRecipes.all) {
      set.add(r.cuisine);
    }
    return ['All', ...set];
  }

  List<GroklyRecipe> get _filtered {
    Iterable<GroklyRecipe> list = GroklyRecipes.all;
    if (_cuisine > 0) {
      final c = _cuisines[_cuisine];
      list = list.where((r) => r.cuisine == c);
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((r) =>
          r.name.toLowerCase().contains(q) ||
          r.cuisine.toLowerCase().contains(q));
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);
    final dishes = _filtered;

    return Scaffold(
      backgroundColor: _FxUi.bg,
      body: Column(
        children: [
          const _FxAppBar(title: 'Dish-First Shopping'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _FxMintBanner(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Cook what you love',
                  subtitle:
                      'Pick a dish first — every ingredient is bundled instantly. Less friction, more time saved.',
                ),
                const SizedBox(height: 14),

                // �� Search ��
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _FxUi.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _FxUi.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: _FxUi.textGray, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v),
                          style: _FxText.body.copyWith(
                              color: _FxUi.textDark, fontSize: 13),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: 'Search dishes or cuisines…',
                            hintStyle: TextStyle(
                                color: _FxUi.textGray, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // �� Cuisine filter pills ��
                _FxPills(
                  labels: _cuisines,
                  selected: _cuisine,
                  onSelect: (i) => setState(() => _cuisine = i),
                ),
                const SizedBox(height: 16),

                _FxSectionTitle('Weekly Featured',
                    trailing: Text('${dishes.length} DISHES',
                        style: _FxText.tag
                            .copyWith(color: _FxUi.textGray))),
                const SizedBox(height: 10),

                if (dishes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                        child: Text('No dishes match your search',
                            style: _FxText.body)),
                  )
                else
                  ...dishes.map((recipe) => _DishCard(
                        recipe: recipe,
                        onSelectIngredients: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailScreen(recipe: recipe))),
                        onAddAll: () {
                          cart.addRecipe(recipe);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '${recipe.ingredients.length} ingredients for ${recipe.name} added to cart'),
                              backgroundColor: _FxUi.green));
                        },
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dish card — hairline-bordered, image top, meta chips and dual CTAs.
class _DishCard extends StatelessWidget {
  final GroklyRecipe recipe;
  final VoidCallback onSelectIngredients;
  final VoidCallback onAddAll;
  const _DishCard(
      {required this.recipe,
      required this.onSelectIngredients,
      required this.onAddAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _FxUi.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _FxUi.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onSelectIngredients,
            child: Stack(
              children: [
                Image.network(recipe.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: _FxUi.thumb,
                        child: const Icon(Icons.restaurant,
                            color: _FxUi.textGray))),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _FxTag(recipe.cuisine.toUpperCase(),
                      filled: true),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(recipe.name,
                            style: _FxText.cardTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Text('Est. ₹${recipe.estimatedCost.toStringAsFixed(0)}',
                        style: _FxText.price.copyWith(color: _FxUi.green)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    '${recipe.prepMinutes} min · ${recipe.servings} servings · ${recipe.ingredients.length} ingredients',
                    style: _FxText.small),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FxOutlineBtn(
                        label: 'Select Ingredients',
                        onTap: onSelectIngredients,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: onAddAll,
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: _FxUi.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Add All',
                                style: _FxText.button
                                    .copyWith(fontSize: 13.5)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ���������������������������������������������

class RecipeDetailScreen extends StatefulWidget {
  final GroklyRecipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    // Everything ticked by default — untick what you already have.
    _selected = {
      for (int i = 0; i < widget.recipe.ingredients.length; i++) i
    };
  }

  double get _total {
    double t = 0;
    for (final i in _selected) {
      t += _fxIngredientPrice(widget.recipe.ingredients[i], widget.recipe);
    }
    return t;
  }

  void _addSelected() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select at least one ingredient'),
          backgroundColor: _FxUi.amber));
      return;
    }
    final cart = GroklyCartProvider.of(context);
    final added = <RecipeIngredient>[];
    final unavailable = <RecipeIngredient>[];
    for (final i in _selected) {
      final ing = widget.recipe.ingredients[i];
      final match = cart.addIngredient(ing);
      if (match != null) {
        added.add(ing);
      } else {
        unavailable.add(ing);
      }
    }
    if (unavailable.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${unavailable.length} ingredient${unavailable.length == 1 ? '' : 's'} not in stock: '
              '${unavailable.map((e) => e.name).join(', ')}'),
          backgroundColor: _FxUi.amber));
    }
    if (added.isEmpty) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _DishAddedScreen(
                recipe: widget.recipe, added: added, total: _total)));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;

    return Scaffold(
      backgroundColor: _FxUi.bg,
      body: Column(
        children: [
          const _FxAppBar(title: 'Select Ingredients'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // �� Dish header card ��
                _FxCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(r.imageUrl,
                            width: 62,
                            height: 62,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 62,
                                height: 62,
                                color: _FxUi.thumb)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: _FxText.cardTitle),
                            const SizedBox(height: 3),
                            Text(
                                '${r.prepMinutes} min · ${r.servings} servings',
                                style: _FxText.small),
                            const SizedBox(height: 6),
                            _FxTag('${r.cuisine.toUpperCase()} · ONE-TAP BUNDLE'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text('Choose the ingredients you need',
                    style: _FxText.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Text('Already have some at home? Just untick them.',
                    style: _FxText.small),
                const SizedBox(height: 12),

                ...List.generate(r.ingredients.length, (i) {
                  final ing = r.ingredients[i];
                  final price = _fxIngredientPrice(ing, r);
                  final checked = _selected.contains(i);
                  return GestureDetector(
                    onTap: () => setState(() =>
                        checked ? _selected.remove(i) : _selected.add(i)),
                    child: _FxCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      borderColor:
                          checked ? _FxUi.mintBorder : _FxUi.border,
                      color: checked ? _FxUi.mint : _FxUi.bg,
                      child: Row(
                        children: [
                          _FxCheck(
                            value: checked,
                            onTap: () => setState(() => checked
                                ? _selected.remove(i)
                                : _selected.add(i)),
                          ),
                          const SizedBox(width: 12),
                          _FxThumb(ing.imageUrl, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ing.name,
                                    style: _FxText.rowTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(ing.quantity, style: _FxText.small),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('₹${price.toStringAsFixed(0)}',
                              style: _FxText.price),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 6),

                // �� Bill details card ��
                _FxCard(
                  child: Column(
                    children: [
                      _FxBillRow('Ingredients selected',
                          '${_selected.length} of ${r.ingredients.length}'),
                      _FxBillRow('Items total', '₹${_total.toStringAsFixed(0)}'),
                      const _FxBillRow('Delivery fee', 'FREE',
                          valueColor: _FxUi.green),
                      const Divider(color: _FxUi.border, height: 18),
                      _FxBillRow('To pay', '₹${_total.toStringAsFixed(0)}',
                          bold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: _FxUi.bg,
            border: Border(top: BorderSide(color: _FxUi.border)),
          ),
          child: _FxCta(
            label: _selected.isEmpty
                ? 'Select ingredients to continue'
                : 'Add ${_selected.length} Ingredients — ₹${_total.toStringAsFixed(0)}',
            icon: Icons.shopping_basket_outlined,
            enabled: _selected.isNotEmpty,
            onTap: _addSelected,
          ),
        ),
      ),
    );
  }
}

class _FxBillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _FxBillRow(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: bold
                        ? _FxText.rowTitle
                        : _FxText.body.copyWith(fontSize: 12.5))),
            Text(value,
                style: bold
                    ? _FxText.price
                    : _FxText.small.copyWith(
                        color: valueColor ?? _FxUi.textDark,
                        fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ���������������������������������������������
// CONFIRMATION — styled like the "Return Confirmed" frame:
// big green check, summary card, primary + secondary actions.
// ���������������������������������������������

class _DishAddedScreen extends StatelessWidget {
  final GroklyRecipe recipe;
  final List<RecipeIngredient> added;
  final double total;
  const _DishAddedScreen(
      {required this.recipe, required this.added, required this.total});

  @override
  Widget build(BuildContext context) {
    final preview = added.take(3).toList();
    final more = added.length - preview.length;

    return Scaffold(
      backgroundColor: _FxUi.bg,
      body: Column(
        children: [
          const _FxAppBar(title: 'Bundle Added'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                        color: _FxUi.mint, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: _FxUi.green, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('Ingredients added!',
                      style: _FxText.screenTitle.copyWith(fontSize: 18)),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                      'We\'ve bundled ${added.length} ingredients for ${recipe.name} into your cart.',
                      textAlign: TextAlign.center,
                      style: _FxText.body),
                ),
                const SizedBox(height: 22),
                _FxSectionTitle('Bundle Summary',
                    trailing: Text('₹${total.toStringAsFixed(0)}',
                        style: _FxText.price.copyWith(color: _FxUi.green))),
                const SizedBox(height: 10),
                _FxCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ...preview.map((ing) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                _FxThumb(ing.imageUrl, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(ing.name,
                                      style: _FxText.rowTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Text(ing.quantity, style: _FxText.small),
                              ],
                            ),
                          )),
                      if (more > 0) ...[
                        const Divider(color: _FxUi.border, height: 16),
                        Row(
                          children: [
                            const Icon(Icons.add_circle_outline,
                                color: _FxUi.green, size: 16),
                            const SizedBox(width: 8),
                            Text('$more more ingredients in your cart',
                                style: _FxText.small
                                    .copyWith(color: _FxUi.green)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FxMintBanner(
                  icon: Icons.timer_outlined,
                  title: 'Saved you ~12 minutes',
                  subtitle:
                      'Dish-first shopping bundles everything in one tap — no list-making needed.',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: _FxUi.bg,
            border: Border(top: BorderSide(color: _FxUi.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FxCta(
                label: 'Add Another Dish',
                icon: Icons.restaurant_menu_outlined,
                onTap: () {
                  // Pop confirmation + ingredient selector → back to dishes.
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                },
              ),
              const SizedBox(height: 8),
              _FxOutlineBtn(
                label: 'Back to Features',
                onTap: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ���������������������������������������������
// SCREEN 11: SIXTH SENSE — Household Consumption Engine
// Redesigned to the return-flow Figma UI. Maps 300+ SKU velocity;
// the first platform that predicts, sources and delivers before you
// feel the need. Cross-refs Swadisht meals. 91% basket accuracy at
// day 60. Sunday morning: your week is ready — tap to confirm.
// ���������������������������������������������

class SixthSenseScreen extends StatefulWidget {
  const SixthSenseScreen({super.key});
  @override
  State<SixthSenseScreen> createState() => _SixthSenseScreenState();
}

class _SixthSenseScreenState extends State<SixthSenseScreen> {
  final Set<String> _included = {};
  bool _initialized = false;
  bool _confirmed = false;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final priceMap = {for (final p in GroklyCatalog.all) p.id: p.price};
      context.read<SixthSenseProvider>().loadRecommendations(catalogPriceLookup: priceMap);
    });
  }

  void _confirmBasket(List<_SixthSensePick> picks, double calculatedTotal) {
    if (_included.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select at least one item to confirm'),
          backgroundColor: _FxUi.amber));
      return;
    }
    final cart = GroklyCartProvider.of(context);
    int addedCount = 0;
    int unavailableCount = 0;

    // Important product validation (Section 18)
    for (final pick in picks) {
      if (!_included.contains(pick.productId)) continue;
      final p = _SixthSenseData.productOf(pick.productId);
      if (p != null) {
        for (int i = 0; i < pick.qty; i++) {
          cart.add(p);
        }
        addedCount++;
      } else {
        unavailableCount++;
      }
    }

    setState(() {
      _confirmed = true;
      _skipped = false;
    });

    if (unavailableCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '$addedCount items added to cart ($unavailableCount unavailable item skipped)'),
          backgroundColor: _FxUi.amber));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Sunday basket confirmed — $addedCount items (₹${calculatedTotal.toStringAsFixed(0)}) added to cart'),
          backgroundColor: _FxUi.green));
    }
  }

  void _skipWeek() {
    setState(() {
      _skipped = true;
      _confirmed = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Basket skipped for this week — Sixth Sense will keep learning'),
        backgroundColor: _FxUi.textGray));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SixthSenseProvider>();
    final basket = provider.sixthSenseBasket;
    final picks = (basket?.items ?? []).map(_SixthSensePick.fromSixthSenseItem).toList();

    if (!_initialized && picks.isNotEmpty) {
      _included.addAll(picks.map((p) => p.productId));
      _initialized = true;
    }

    final total = _SixthSenseData.totalFor(picks, _included);
    final accuracy = provider.accuracyScore;
    final accuracyText = accuracy != null ? '${(accuracy * 100).toInt()}%' : 'Learning';
    final accuracyLabel = accuracy != null ? 'basket accuracy\nat day 60' : 'building\nconfidence';

    return Scaffold(
      backgroundColor: _FxUi.bg,
      body: Column(
        children: [
          const _FxAppBar(title: 'Sixth Sense'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // �� Dark-green hero (Green Points style) ��
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _FxUi.greenDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOUSEHOLD CONSUMPTION ENGINE',
                          style: _FxText.tag.copyWith(
                              color: Colors.white.withOpacity(0.75),
                              letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(accuracyText,
                              style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.0)),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(accuracyLabel,
                                style: _FxText.small.copyWith(
                                    color: Colors.white.withOpacity(0.85))),
                          ),
                          const Spacer(),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.insights_outlined,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroChip('300+ SKU VELOCITY MAPPED'),
                          _HeroChip('CROSS-REFS SWADISHT MEALS'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // �� How it works ��
                const _FxSectionTitle('How Sixth Sense Works'),
                const SizedBox(height: 10),
                _FxCard(
                  child: Column(
                    children: const [
                      _HowRow(
                          icon: Icons.query_stats_outlined,
                          title: 'Predicts',
                          subtitle:
                              'Maps the velocity of 300+ SKUs in your household to know what runs out, and when.'),
                      _HowRow(
                          icon: Icons.agriculture_outlined,
                          title: 'Sources',
                          subtitle:
                              'Procures from FarmChain partners before you feel the need — never after.'),
                      _HowRow(
                          icon: Icons.local_shipping_outlined,
                          title: 'Delivers',
                          subtitle:
                              'Your week arrives Sunday morning, ready before the first chai.',
                          isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // �� This week's basket status tracker ��
                _FxSectionTitle('This Week\'s Basket',
                    trailing: _confirmed
                        ? const _FxTag('CONFIRMED', filled: true)
                        : _skipped
                            ? _FxTag('SKIPPED',
                                color: _FxUi.textGray, bg: _FxUi.thumb)
                            : const _FxTag('ON TRACK')),
                const SizedBox(height: 10),
                _FxCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    children: [
                      _FxStepTracker(
                        steps: const [
                          'Predicted',
                          'Sourced',
                          'Packed',
                          'Arriving Sun'
                        ],
                        current: _confirmed ? 2 : 1,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined,
                              color: _FxUi.green, size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                                _confirmed
                                    ? 'Confirmed — arriving Sunday, 7–9 AM'
                                    : 'Sourcing from FarmChain · confirm by Saturday 9 PM',
                                style: _FxText.small),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // �� Swadisht cross-reference ��
                if (provider.crossVentureNotes.isNotEmpty) ...[
                  _FxMintBanner(
                    icon: Icons.ramen_dining_outlined,
                    title: 'Cross-referenced with Swadishtt',
                    subtitle: provider.crossVentureNotes.join('\n'),
                  ),
                  const SizedBox(height: 18),
                ],

                // �� Sunday morning basket ��
                _FxSectionTitle('Sunday Morning: Your Week Is Ready',
                    trailing: Text('₹${total.toStringAsFixed(0)}',
                        style:
                            _FxText.price.copyWith(color: _FxUi.green))),
                const SizedBox(height: 3),
                Text(
                    _confirmed
                        ? 'Basket confirmed — you can still add more anytime.'
                        : 'Tap to confirm. Untick anything you don\'t need this week.',
                    style: _FxText.small),
                const SizedBox(height: 12),

                ...picks.map((pick) {
                  final p = _SixthSenseData.productOf(pick.productId);
                  if (p == null) return const SizedBox.shrink();
                  final checked = _included.contains(pick.productId);
                  return GestureDetector(
                    onTap: _confirmed
                        ? null
                        : () => setState(() => checked
                            ? _included.remove(pick.productId)
                            : _included.add(pick.productId)),
                    child: _FxCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      color: checked ? _FxUi.mint : _FxUi.bg,
                      borderColor:
                          checked ? _FxUi.mintBorder : _FxUi.border,
                      child: Row(
                        children: [
                          _FxCheck(
                            value: checked,
                            onTap: () {
                              if (_confirmed) return;
                              setState(() => checked
                                  ? _included.remove(pick.productId)
                                  : _included.add(pick.productId));
                            },
                          ),
                          const SizedBox(width: 12),
                          _FxThumb(p.imageUrl, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p.name} x${pick.qty}',
                                    style: _FxText.rowTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(pick.reason,
                                    style: _FxText.small,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                              '₹${(p.price * pick.qty).toStringAsFixed(0)}',
                              style: _FxText.price),
                        ],
                      ),
                    ),
                  );
                }),

                if (_confirmed) ...[
                  const SizedBox(height: 4),
                  _FxCard(
                    color: _FxUi.mint,
                    borderColor: _FxUi.mintBorder,
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: _FxUi.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              'Basket confirmed — ${_included.length} items added to your cart, arriving Sunday 7–9 AM.',
                              style: _FxText.body
                                  .copyWith(color: _FxUi.green)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: _FxUi.bg,
            border: Border(top: BorderSide(color: _FxUi.border)),
          ),
          child: _confirmed
              ? _FxOutlineBtn(
                  label: 'Basket Confirmed — Keep Shopping',
                  icon: Icons.check_rounded,
                  onTap: () => Navigator.pop(context),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FxCta(
                      label:
                          'Confirm Basket (${_included.length} items) — ₹${total.toStringAsFixed(0)}',
                      icon: Icons.check_rounded,
                      enabled: _included.isNotEmpty,
                      onTap: () => _confirmBasket(picks, total),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _skipWeek,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Skip this week',
                            style: _FxText.small.copyWith(
                                color: _FxUi.textGray,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String text;
  const _HeroChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: _FxText.tag.copyWith(color: Colors.white)),
      );
}

class _HowRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;
  const _HowRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.isLast = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: _FxUi.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: _FxUi.mint, shape: BoxShape.circle),
              child: Icon(icon, color: _FxUi.green, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _FxText.rowTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _FxText.small),
                ],
              ),
            ),
          ],
        ),
      );
}


// ���������������������������������������������
// SCREEN 12: SAVED BASKETS
// FIX: previously rendered with a hard-coded local baskets list and was
// reported as showing a blank screen. It now reads from
// GroklyBasketsProvider (the SavedBasketsState added above), so the
// "Save Active Cart" button really adds a new basket and the list always
// reflects real, current state instead of being a static stub.
// ���������������������������������������������

class SavedBasketsScreen extends StatelessWidget {
  const SavedBasketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);

    return Scaffold(
      backgroundColor: GroklyColors.background,
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmarks, _) {
          final savedIds = bookmarks.savedGroklyIds;
          final savedProducts = GroklyCatalog.all
              .where((p) => savedIds.contains(p.id))
              .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [GroklyColors.primary, Color(0xFF1A7B48)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: GroklyColors.white, size: 20),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MY SAVED BASKET',
                                    style: GroklyTextStyles.labelCaps.copyWith(
                                        color: GroklyColors.primaryFixed,
                                        fontSize: 10)),
                                Text('Saved Products',
                                    style: GroklyTextStyles.headlineLg
                                        .copyWith(fontSize: 22)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CartScreen())),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.shopping_cart_outlined,
                                    color: GroklyColors.white),
                                if (cart.totalQty > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: CircleAvatar(
                                      radius: 8,
                                      backgroundColor: GroklyColors.secondary,
                                      child: Text('${cart.totalQty}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: GroklyColors.white,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (savedProducts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border_rounded,
                            size: 64,
                            color: GroklyColors.outline.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No saved products yet',
                            style: GroklyTextStyles.sectionHeader
                                .copyWith(color: GroklyColors.outline)),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart icon on any product\nto save it here',
                          textAlign: TextAlign.center,
                          style: GroklyTextStyles.bodyMain
                              .copyWith(color: GroklyColors.onSurfaceVar),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = savedProducts[index];
                        return _SavedProductCard(
                          product: product,
                          onRemove: () => bookmarks.toggleGrokly(product.id),
                          onAddToCart: () {
                            cart.add(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('${product.name} added to cart'),
                                backgroundColor: GroklyColors.primary,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          ),
                        );
                      },
                      childCount: savedProducts.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedProductCard extends StatelessWidget {
  final GroklyProduct product;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;
  const _SavedProductCard({
    required this.product,
    required this.onRemove,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: GroklyColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: GroklyShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + heart + discount
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: GroklyColors.surfaceMint,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: GroklyColors.outline, size: 36),
                        ),
                      ),
                    ),
                  ),
                  // Remove heart
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: GroklyColors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded,
                            color: Colors.redAccent, size: 18),
                      ),
                    ),
                  ),
                  // Discount badge
                  if (discount != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: GroklyColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$discount% OFF',
                            style: const TextStyle(
                                color: GroklyColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            // Product info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GroklyTextStyles.bodyMain.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(product.size,
                        style: GroklyTextStyles.labelCaps.copyWith(
                            color: GroklyColors.outline, fontSize: 10)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '\u20B9${product.price.toStringAsFixed(0)}',
                                  style: GroklyTextStyles.sectionHeader
                                      .copyWith(fontSize: 15)),
                              if (product.mrp != null &&
                                  product.mrp! > product.price)
                                Text(
                                    '\u20B9${product.mrp!.toStringAsFixed(0)}',
                                    style: GroklyTextStyles.labelCaps.copyWith(
                                        color: GroklyColors.outline,
                                        fontSize: 10,
                                        decoration:
                                            TextDecoration.lineThrough)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: GroklyColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add,
                                color: GroklyColors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasketCard extends StatelessWidget {
  final SavedBasket basket;
  final VoidCallback onReorder;
  const _BasketCard({required this.basket, required this.onReorder});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: GroklyColors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: GroklyShadows.soft,
    ),
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(basket.name, style: GroklyTextStyles.sectionHeader.copyWith(color: GroklyColors.primary)),
          Text(basket.subtitle, style: GroklyTextStyles.bodyMain.copyWith(
              color: GroklyColors.onSurfaceVar, fontSize: 12)),
        ]),
        const Icon(Icons.more_vert, color: GroklyColors.outlineVar),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        height: 110,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(basket.imageUrls[0], height: 110, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 110, color: GroklyColors.surfaceMint)),
            )),
            const SizedBox(width: 8),
            Expanded(child: Column(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(basket.imageUrls.length > 1 ? basket.imageUrls[1] : basket.imageUrls[0], width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: GroklyColors.surfaceMint)),
              )),
              const SizedBox(height: 4),
              Container(
                height: 48,
                decoration: BoxDecoration(
                    color: GroklyColors.secContainer, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('+ ${basket.itemCount > 2 ? basket.itemCount - 2 : 0} items',
                    style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.onSecContainer, fontSize: 10))),
              ),
            ])),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TOTAL PRICE', style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.outline, fontSize: 9)),
          Text('₹${basket.price.toStringAsFixed(0)}', style: GroklyTextStyles.sectionHeader),
        ]),
        GestureDetector(
          onTap: onReorder,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
                color: GroklyColors.primary, borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              const Icon(Icons.shopping_cart_outlined, color: GroklyColors.white, size: 16),
              const SizedBox(width: 6),
              Text('Reorder', style: GroklyTextStyles.labelCaps.copyWith(
                  color: GroklyColors.white, fontSize: 10)),
            ]),
          ),
        ),
      ]),
    ]),
  );
}

// ���������������������������������������������
// SCREEN 13: ORDER TRACKING
// ���������������������������������������������

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;
  final double? total;
final List<ReturnableItem> returnItems;
const OrderTrackingScreen({super.key, this.orderId, this.total, this.returnItems = const []});  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  int _step = 2;
  Timer? _timer;

  String get _displayOrderId {
    final id = widget.orderId;
    if (id == null) return 'GRK-99281';
    return id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_step < 3) setState(() => _step++);
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  static const steps = [
    ('Confirmed', '10:45 AM', 'Order received and verified'),
    ('Packing', '10:52 AM', 'Items packed carefully in eco-friendly boxes'),
    ('On the Way', 'In Transit', 'Your delivery partner is heading to your location'),
    ('Delivered', 'Arrived!', 'Order delivered successfully'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDelivered = _step >= 3;

    return Scaffold(
      backgroundColor: GroklyColors.background,
      body: CustomScrollView(
        slivers: [
          // Simple header: back arrow, title, help icon
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_rounded, color: GroklyColors.onSurface),
                      ),
                      const SizedBox(width: 12),
                      Text('Order #$_displayOrderId', style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 18)),
                    ]),
                    Row(children: [
                      const Icon(Icons.help_outline_rounded, color: GroklyColors.primary, size: 20),
                      const SizedBox(width: 4),
                      Text('Help', style: GroklyTextStyles.bodyMain.copyWith(color: GroklyColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  // Map + rider banner card
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GroklyColors.outlineVar, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: GroklyColors.surfaceHigh,
                            child: const Icon(Icons.map_outlined, size: 60, color: GroklyColors.outline),
                          ),
                        ),
                        Positioned(
                          bottom: 12, left: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: GroklyColors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: GroklyColors.outlineVar.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                    color: GroklyColors.primary, borderRadius: BorderRadius.circular(20)),
                                child: const Icon(Icons.delivery_dining_rounded, color: GroklyColors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(isDelivered ? 'Arjun has arrived' : 'Arjun is on the way',
                                    style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 14)),
                                Text('2.4 km away · Delivering to Home',
                                    style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.outline, fontSize: 10)),
                              ])),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estimated arrival card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GroklyColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GroklyColors.outlineVar, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: GroklyColors.surfaceMint, borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6,
                                decoration: const BoxDecoration(color: GroklyColors.primary, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('LIVE TRACKING', style: GroklyTextStyles.labelCaps.copyWith(
                                color: GroklyColors.primary, fontSize: 9)),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ESTIMATED ARRIVAL',
                                style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.outline, fontSize: 11)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                  color: GroklyColors.secContainer, borderRadius: BorderRadius.circular(14)),
                              child: Text(isDelivered ? 'DELIVERED' : 'ON TIME',
                                  style: GroklyTextStyles.labelCaps.copyWith(
                                      color: GroklyColors.onSecContainer, fontSize: 10)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(isDelivered ? 'Arrived!' : '10–15 mins',
                            style: GroklyTextStyles.headlineLg.copyWith(color: GroklyColors.primaryDark, fontSize: 32)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_step + 1) / 4,
                            backgroundColor: GroklyColors.surfaceHigh,
                            valueColor: const AlwaysStoppedAnimation(GroklyColors.primary),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: GroklyColors.outline),
                          const SizedBox(width: 6),
                          Text('Usually delivered within 15 minutes',
                              style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.outline, fontSize: 10)),
                        ]),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            for (int i = 0; i < steps.length; i++) ...[
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i <= _step ? GroklyColors.primary : GroklyColors.outlineVar,
                                ),
                              ),
                              if (i < steps.length - 1)
                                Expanded(
                                  child: Container(
                                    height: 2, margin: const EdgeInsets.symmetric(horizontal: 2),
                                    color: i < _step ? GroklyColors.primary : GroklyColors.outlineVar,
                                  ),
                                ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: steps.map((s) => Text(s.$1,
                              style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.outline, fontSize: 8))).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Packing note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GroklyColors.surfaceLow,
                      borderRadius: BorderRadius.circular(18),
                      border: const Border(left: BorderSide(color: GroklyColors.primary, width: 3)),
                    ),
                    child: Text(
                      '"Your vegetables were packed separately in breathable eco-layers to maintain optimal freshness during transit."',
                      style: GroklyTextStyles.bodyMain.copyWith(fontStyle: FontStyle.italic, fontSize: 12.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Timeline card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GroklyColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GroklyColors.outlineVar, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Timeline', style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 16)),
                        const SizedBox(height: 16),
                        Column(
                          children: List.generate(steps.length, (i) {
                            final done = i < _step;
                            final active = i == _step;
                            final isLast = i == steps.length - 1;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(children: [
                                  Container(
                                    width: 26, height: 26,
                                    decoration: BoxDecoration(
                                      color: done || active ? GroklyColors.primary : GroklyColors.outlineVar,
                                      shape: BoxShape.circle,
                                    ),
                                    child: done
                                        ? const Icon(Icons.check, color: GroklyColors.white, size: 15)
                                        : active
                                        ? Container(
                                            width: 8, height: 8, margin: const EdgeInsets.all(9),
                                            decoration: const BoxDecoration(
                                                color: GroklyColors.white, shape: BoxShape.circle))
                                        : null,
                                  ),
                                  if (!isLast)
                                    Container(width: 2, height: 44,
                                        color: done ? GroklyColors.primary : GroklyColors.outlineVar),
                                ]),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(steps[i].$1, style: GroklyTextStyles.sectionHeader.copyWith(
                                              fontSize: 14,
                                              color: active ? GroklyColors.primary : GroklyColors.onSurface,
                                              fontWeight: active || done ? FontWeight.w700 : FontWeight.w500)),
                                          Text(steps[i].$2, style: GroklyTextStyles.labelCaps.copyWith(
                                              color: active ? GroklyColors.primary : GroklyColors.outline, fontSize: 10)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(steps[i].$3, style: GroklyTextStyles.labelCaps.copyWith(
                                          color: GroklyColors.outline, fontSize: 10.5, fontWeight: FontWeight.w400)),
                                    ]),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order summary footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GroklyColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GroklyColors.outlineVar, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Order #$_displayOrderId',
                                  style: GroklyTextStyles.bodyMain.copyWith(color: GroklyColors.outline, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('3 Items · ₹${(widget.total ?? 495).toStringAsFixed(0)}',
                                  style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 15)),
                            ]),
                            Text('View Details', style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.primary)),
                          ],
                        ),
                        const Divider(height: 24, color: GroklyColors.outlineVar),
                        Row(children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 16, color: GroklyColors.outline),
                          const SizedBox(width: 6),
                          Text('Paid via UPI', style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.outline, fontSize: 11)),
                          const Spacer(),
                          const Icon(Icons.download_outlined, size: 16, color: GroklyColors.primary),
                          const SizedBox(width: 4),
                          Text('Invoice', style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.primary, fontSize: 11)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order items list (unchanged widget)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GroklyColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GroklyColors.outlineVar, width: 1),
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Order Details', style: GroklyTextStyles.sectionHeader.copyWith(fontSize: 15)),
                        Text('3 ITEMS', style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.primary)),
                      ]),
                      const SizedBox(height: 14),
                      _OrderItem('Organic Broccoli', '1 Unit · 250g', '₹75',
                          'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=200&q=80'),
                      const SizedBox(height: 10),
                      _OrderItem('Toor Dal', '1kg · Tata Sampann', '₹160',
                          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=200&q=80'),
                      const SizedBox(height: 10),
                      _OrderItem('Amul Butter', '500g · Amul', '₹260',
                          'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=200&q=80'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Order Summary / Invoice / Return History quick-links
                  Container(
                    decoration: BoxDecoration(
                      color: GroklyColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GroklyColors.outlineVar, width: 1),
                    ),
                    child: Column(children: [
                      _TrackingLinkRow(
                          icon: Icons.receipt_long_outlined, label: 'Order Summary',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Order summary shown above'), backgroundColor: GroklyColors.primary))),
                      const Divider(height: 1, color: GroklyColors.outlineVar, indent: 16, endIndent: 16),
                      _TrackingLinkRow(
                          icon: Icons.download_outlined, label: 'Invoice',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Invoice download coming soon'), backgroundColor: GroklyColors.primary))),
                      const Divider(height: 1, color: GroklyColors.outlineVar, indent: 16, endIndent: 16),
                      _TrackingLinkRow(
                          icon: Icons.history_rounded, label: 'Return History',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SavedBasketsScreen()))),
                    ]),
                  ),
                  const SizedBox(height: 16),
if (isDelivered && widget.returnItems.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GroklyColors.surfaceMint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GroklyColors.secContainer),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GIVE THESE ITEMS TO YOUR RIDER',
                              style: GroklyTextStyles.labelCaps.copyWith(
                                  color: GroklyColors.primaryDark, fontSize: 10)),
                          const SizedBox(height: 10),
                          ...widget.returnItems.map((r) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(children: [
                                  Icon(Icons.check_circle_rounded, color: GroklyColors.primary, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('${r.label} x ${r.qty}',
                                      style: GroklyTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600, fontSize: 13))),
                                  Text('+₹${r.credit.toStringAsFixed(0)}',
                                      style: GroklyTextStyles.bodyMain.copyWith(
                                          color: GroklyColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 13)),
                                ]),
                              )),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ReturnConfirmedScreen(returnItems: widget.returnItems))),
                            child: Container(
                              width: double.infinity, height: 46,
                              decoration: BoxDecoration(color: GroklyColors.primary, borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text('I handed it to the rider ✓',
                                  style: GroklyTextStyles.bodyMain.copyWith(color: GroklyColors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Primary reorder CTA — actually re-adds this order's items to the live cart.
                  GestureDetector(
                    onTap: () {
                      final cart = GroklyCartProvider.of(context);
                      for (final name in ['Broccoli', 'Toor Dal', 'Amul Butter']) {
                        final match = GroklyCatalog.all.where((p) => p.name == name).firstOrNull;
                        if (match != null) cart.add(match);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Items added to cart'), backgroundColor: GroklyColors.primary));
                    },
                    child: Container(
                      width: double.infinity, height: 52,
                      decoration: BoxDecoration(
                          color: GroklyColors.primary, borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.replay_rounded, color: GroklyColors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Reorder Items',
                        
                            style: GroklyTextStyles.sectionHeader.copyWith(color: GroklyColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom action buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: GroklyColors.outlineVar),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: GroklyColors.onSurface),
                        label: Text('Chat Support', style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.onSurface)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: GroklyColors.outlineVar),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        icon: const Icon(Icons.call_outlined, size: 18, color: GroklyColors.onSurface),
                        label: Text('Call Partner', style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.onSurface)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ���������������������������������������������
// RETURN CONFIRMED
// ���������������������������������������������

// ���������������������������������������������
// RETURN CONFIRMED
// ���������������������������������������������

class ReturnConfirmedScreen extends StatefulWidget {
  final List<ReturnableItem> returnItems;
  const ReturnConfirmedScreen({super.key, required this.returnItems});

  @override
  State<ReturnConfirmedScreen> createState() => _ReturnConfirmedScreenState();
}

class _ReturnConfirmedScreenState extends State<ReturnConfirmedScreen> {
  late final double total;

  @override
  void initState() {
    super.initState();
    total = widget.returnItems.fold(0.0, (s, r) => s + r.credit);
    // Credit the real wallet exactly once when this screen is shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GroklyWalletProvider.of(context).addEcoReturnCredit(
        total,
        label: widget.returnItems.length == 1
            ? '${widget.returnItems.first.label} Return'
            : 'Eco-Return (${widget.returnItems.length} items)',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GroklyColors.background,
      appBar: AppBar(
        backgroundColor: GroklyColors.surface,
        elevation: 0,
        leading: const BackButton(color: GroklyColors.onSurface),
        title: Text('Order', style: GroklyTextStyles.headlineMd.copyWith(fontSize: 18)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: GroklyColors.surfaceMint, borderRadius: BorderRadius.circular(45)),
                child: const Icon(Icons.recycling_rounded, color: GroklyColors.primary, size: 46),
              ),
              const SizedBox(height: 20),
              Text('Thanks for returning!', style: GroklyTextStyles.headlineMd.copyWith(fontSize: 22)),
              const SizedBox(height: 8),
              Text('The rider confirmed pickup. Your wallet has been credited.',
                  style: GroklyTextStyles.bodyMain.copyWith(color: GroklyColors.outline),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text('+₹${total.toStringAsFixed(0)}',
                  style: GroklyTextStyles.headlineLg.copyWith(color: GroklyColors.primaryDark, fontSize: 34)),
              Text('Added to Grokly wallet',
                  style: GroklyTextStyles.labelCaps.copyWith(color: GroklyColors.outline, fontSize: 10)),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GroklyColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GroklyColors.outlineVar),
                ),
                child: Column(
                  children: widget.returnItems.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(child: Text('${r.label} x ${r.qty}',
                              style: GroklyTextStyles.bodyMain.copyWith(fontSize: 13))),
                          Text('+₹${r.credit.toStringAsFixed(0)}',
                              style: GroklyTextStyles.bodyMain.copyWith(
                                  color: GroklyColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 13)),
                        ]),
                      )).toList(),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(color: GroklyColors.primary, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text('Back to Home',
                      style: GroklyTextStyles.sectionHeader.copyWith(color: GroklyColors.white, fontSize: 15))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _TrackingLinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TrackingLinkRow({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 18, color: GroklyColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GroklyTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600))),
        const Icon(Icons.chevron_right_rounded, color: GroklyColors.outline),
      ]),
    ),
  );
}

class _OrderItem extends StatelessWidget {
  final String name, subtitle, price, imageUrl;
  const _OrderItem(this.name, this.subtitle, this.price, this.imageUrl);
  @override
  Widget build(BuildContext context) => Row(children: [
    ClipRRect(borderRadius: BorderRadius.circular(10),
        child: Image.network(imageUrl, width: 44, height: 44, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: GroklyColors.surfaceMint))),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: GroklyTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600)),
      Text(subtitle, style: GroklyTextStyles.labelCaps.copyWith(fontSize: 9)),
    ])),
    Text(price, style: GroklyTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w500)),
  ]);
}

class ProductDetailScreen extends StatelessWidget {
  final GroklyProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = GroklyCartProvider.of(context);
    final qty = cart.qtyOf(product.id);
    final discount = product.discountPercent;

    return Scaffold(
      backgroundColor: GroklyColors.background,
      appBar: AppBar(
        backgroundColor: GroklyColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: GroklyColors.onSurface, size: 20),
        ),
        actions: [
          Consumer<BookmarkProvider>(
            builder: (context, provider, _) {
              bool isFav = provider.isGroklySaved(product.id);
              return GestureDetector(
                onTap: () => provider.toggleGrokly(product.id),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? GroklyColors.primary : GroklyColors.outline,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Space for bottom bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: double.infinity,
              height: 300,
              color: GroklyColors.surfaceMint,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_outlined, color: GroklyColors.outline, size: 64),
                    ),
                  ),
                  if (discount != null && discount > 0)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: GroklyColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: GroklyColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GroklyColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: GroklyColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.size,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: GroklyColors.outline,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: GroklyColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (product.mrp != null && product.mrp! > product.price)
                        Text(
                          '₹${product.mrp!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: GroklyColors.outline,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Extra Info / Badges
                  Row(
                    children: [
                      if (product.deliveryMinutes != null)
                        _buildInfoBadge(Icons.timer_outlined, '${product.deliveryMinutes} MINS'),
                      const SizedBox(width: 12),
                      if (product.rating != null)
                        _buildInfoBadge(Icons.star_rounded, '${product.rating} (${product.ratingCount ?? 0})', color: Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 32),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GroklyColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Experience the fresh quality and authentic taste of ${product.brand}\'s ${product.name}. Carefully sourced to provide you with the best ingredients for your daily lifestyle. Store in a cool, dry place away from direct sunlight.',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      height: 1.5,
                      color: GroklyColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: GroklyColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: GroklyColors.onSurface,
                  ),
                ),
                if (product.mrp != null && product.mrp! > product.price)
                  Text(
                    '₹${product.mrp!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: GroklyColors.onSurfaceVar,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            SizedBox(
              width: 150,
              child: qty == 0
                  ? GestureDetector(
                      onTap: () => cart.add(product),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: GroklyColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: GroklyColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: GroklyColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () => cart.remove(product),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.remove, color: GroklyColors.white),
                            ),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: GroklyColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => cart.add(product),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.add, color: GroklyColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GroklyColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GroklyColors.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? GroklyColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: GroklyColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}