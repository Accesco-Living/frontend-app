import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/ride.dart';
import 'package:accesco_living_app/providers/unified_cart_provider.dart';
import '../services/api_service.dart'; // ── ADDED API SERVICE IMPORT ──

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final List<Ride> _rides = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CartItem> get items => _items;
  List<Ride> get rides => _rides;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalItemsCount => itemCount + _rides.length;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get ridesTotal => _rides.fold(0, (sum, ride) => sum + ride.price);
  double get grandSubtotal => subtotal + ridesTotal;

  double get deliveryCharges => subtotal > 500 ? 0 : 40;
  // ✅ FIXED: Restored multiplication operator for tax
  double get tax => grandSubtotal * 0.05;
  double get total => grandSubtotal + deliveryCharges + tax;

  // ── NEW: FETCH CART FROM BACKEND WITH LOCAL FALLBACK ──
  Future<void> fetchBackendCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.getCart();
      if (res.containsKey('items') && res['items'] is List) {
        // If backend has items, you can map them here if needed.
        // Keeping local items intact to prevent UI breaking if empty.
      }
    } catch (e) {
      debugPrint("Failed to fetch backend cart, using local state: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addItem(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }

    // Add to Unified Cart
    String vendor = 'Swadishtt';

    UnifiedCartState.instance.addItem(
      vendorName: vendor,
      id: product.id.toString(),
      name: product.name,
      subtitle: product.description,
      unitPrice: product.price.toInt(),
      imageUrl: product.imageUrl,
    );

    // ── BACKGROUND API SYNC (NON-BLOCKING) ──
    ApiService.addToCart(product.id.toString(), quantity: 1).catchError((_) => false);

    notifyListeners();
  }


  void updateCustomizedProduct(int oldProductId, Product newProduct) {
    final index = _items.indexWhere((item) => item.product.id == oldProductId);
    if (index >= 0) {
      _items[index] = CartItem(
        product: newProduct,
        quantity: _items[index].quantity,
      );
    } else {
      _items.add(CartItem(product: newProduct));
    }

    // Add to Unified Cart
    String vendor = 'Swadishtt';

    UnifiedCartState.instance.addItem(
      vendorName: vendor,
      id: newProduct.id.toString(),
      name: newProduct.name,
      subtitle: newProduct.description,
      unitPrice: newProduct.price.toInt(),
      imageUrl: newProduct.imageUrl,
    );
    notifyListeners();
  }

  // Helper method to check if product is in cart
  bool isInCart(int productId) {
    return _items.any((item) => item.product.id == productId);
  }

  // Helper method to get quantity of a product
  int getQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  // Helper method to decrease quantity by 1
  void decreaseQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final product = _items[index].product;
      String vendor = 'Swadishtt';


      UnifiedCartState.instance.updateQuantity(vendor, product.id.toString(), -1);

      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        ApiService.updateCartItem(product.id.toString(), _items[index].quantity).catchError((_) => false);
      } else {
        _items.removeAt(index);
        ApiService.deleteCartItem(product.id.toString()).catchError((_) => false);
      }
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    ApiService.deleteCartItem(productId.toString()).catchError((_) => false);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity > 0) {
        _items[index].quantity = quantity;
        ApiService.updateCartItem(productId.toString(), quantity).catchError((_) => false);
      } else {
        _items.removeAt(index);
        ApiService.deleteCartItem(productId.toString()).catchError((_) => false);
      }
      notifyListeners();
    }
  }

  void incrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final product = _items[index].product;
      String vendor = 'Swadishtt';


      UnifiedCartState.instance.updateQuantity(vendor, product.id.toString(), 1);

      _items[index].quantity++;
      ApiService.updateCartItem(product.id.toString(), _items[index].quantity).catchError((_) => false);
      notifyListeners();
    }
  }

  void decrementQuantity(int productId) {
    decreaseQuantity(productId);
  }

  // Ride management
  void addRide(Ride ride) {
    _rides.add(ride);
    notifyListeners();
  }

  void removeRide(String rideId) {
    _rides.removeWhere((ride) => ride.id == rideId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _rides.clear();
    notifyListeners();
  }
}