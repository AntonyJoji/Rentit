import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screen/cart.dart';
import 'package:user/screen/mybookings.dart';
import 'package:user/screen/login.dart';
import 'package:user/screen/productpage.dart';
import 'package:user/screen/settingsPage.dart';
//import 'dart:math';
import 'dart:async';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  List<Map<String, dynamic>> randomItems = []; // For random items
  Map<int, int> itemStocks = {};
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  
  // Add filter state variables
  String selectedCategory = 'All';
  int selectedCategoryId = 0; // 0 means "All"
  RangeValues priceRange = RangeValues(0, 10000);
  bool showOnlyInStock = false;
  List<String> categories = ['All'];
  // Add subcategory variables
  String selectedSubcategory = 'All';
  int selectedSubcategoryId = 0; // 0 means "All"
  List<String> subcategories = ['All'];
  Map<int, List<Map<String, dynamic>>> categoryToSubcategories = {};
  double maxPrice = 10000;
  
  // Add controllers for auto-scrolling
  late PageController _pageController;
  Timer? _autoScrollTimer;
  
  // Add user data variables
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  bool isUserDataLoading = true;

  // Add variables for category data from tbl_catagory
  List<Map<String, dynamic>> categoryData = [];
  List<Map<String, dynamic>> subcategoryData = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    fetchItems();
    fetchUserData();
    fetchCategoriesAndSubcategories(); // Fetch both categories and subcategories
    searchController.addListener(_filterItems);
    // Start auto-scrolling when the page loads
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        if (_pageController.page == randomItems.length - 1) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_user')
          .select('user_name, user_email')
          .eq('user_id', user.id)
          .single();

      setState(() {
        userName = response['user_name'] ?? 'User';
        userEmail = response['user_email'] ?? user.email ?? 'No email';
        isUserDataLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        userName = 'User';
        userEmail = 'No email';
        isUserDataLoading = false;
      });
    }
  }

  Future<void> fetchItems() async {
    try {
      final response = await supabase.from('tbl_item').select();
      final stockResponse = await supabase
          .from('tbl_stock')
          .select('item_id, stock_quantity, stock_date')
          .order('stock_date', ascending: false);

      Map<int, int> stocks = {};
      for (var stock in stockResponse) {
        if (!stocks.containsKey(stock['item_id'])) {
          stocks[stock['item_id']] = stock['stock_quantity'];
        }
      }

      List<Map<String, dynamic>> allItems = List<Map<String, dynamic>>.from(response);
      
      // Determine max price
      double highestPrice = 0;
      
      for (var item in allItems) {
        if (item['item_rentprice'] != null && item['item_rentprice'] > highestPrice) {
          highestPrice = item['item_rentprice'].toDouble();
        }
      }
      
      // Take 4 random items instead of 2
      allItems.shuffle();
      List<Map<String, dynamic>> randomSelection = allItems.take(4).toList();

      setState(() {
        items = allItems;
        filteredItems = List<Map<String, dynamic>>.from(items);
        randomItems = randomSelection;
        itemStocks = stocks;
        isLoading = false;
        maxPrice = highestPrice.ceil().toDouble();
        priceRange = RangeValues(0, maxPrice);
      });
    } catch (e) {
      print('Error fetching items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch categories and subcategories
  Future<void> fetchCategoriesAndSubcategories() async {
    try {
      // Fetch categories
      final categoryResponse = await supabase.from('tbl_category').select('category_id, category_name');
      List<Map<String, dynamic>> cats = List<Map<String, dynamic>>.from(categoryResponse);
      
      // Fetch subcategories
      final subcategoryResponse = await supabase.from('tbl_subcategory')
          .select('subcategory_id, subcategory_name, category_id');
      List<Map<String, dynamic>> subcats = List<Map<String, dynamic>>.from(subcategoryResponse);
      
      // Create a mapping of category_id to subcategories
      Map<int, List<Map<String, dynamic>>> subsByCat = {};
      
      for (var subcat in subcats) {
        int catId = subcat['category_id'];
        if (!subsByCat.containsKey(catId)) {
          subsByCat[catId] = [];
        }
        subsByCat[catId]?.add(subcat);
      }
      
      setState(() {
        categoryData = cats;
        subcategoryData = subcats;
        categoryToSubcategories = subsByCat;
        
        // Update category dropdown options
        categories = ['All'];
        for (var cat in cats) {
          if (cat['category_name'] != null) {
            categories.add(cat['category_name'].toString());
          }
        }
        
        // Initialize subcategories with "All"
        subcategories = ['All'];
      });
    } catch (e) {
      print('Error fetching categories and subcategories: $e');
    }
  }
  
  // Update subcategories when category changes
  void _updateSubcategories(String category) {
    setState(() {
      selectedCategory = category;
      selectedSubcategory = 'All';
      selectedSubcategoryId = 0;
      
      if (category == 'All') {
        subcategories = ['All'];
        selectedCategoryId = 0;
      } else {
        // Find the category_id for the selected category
        int? categoryId;
        for (var cat in categoryData) {
          if (cat['category_name'] == category) {
            categoryId = cat['category_id'];
            break;
          }
        }
        
        selectedCategoryId = categoryId ?? 0;
        
        if (categoryId != null && categoryToSubcategories.containsKey(categoryId)) {
          subcategories = ['All'];
          for (var subcat in categoryToSubcategories[categoryId]!) {
            subcategories.add(subcat['subcategory_name'].toString());
          }
        } else {
          subcategories = ['All'];
        }
      }
    });
    
    _filterItems();
  }

  void _filterItems() {
    setState(() {
      filteredItems = items.where((item) {
        // Filter by search text - check name, category and subcategory
        String itemCategoryName = '';
        String itemSubcategoryName = '';
        
        // Find category and subcategory names based on IDs in the item
        if (item['category_id'] != null) {
          for (var cat in categoryData) {
            if (cat['category_id'] == item['category_id']) {
              itemCategoryName = cat['category_name']?.toString() ?? '';
              break;
            }
          }
        }
        
        if (item['subcategory_id'] != null) {
          for (var subcat in subcategoryData) {
            if (subcat['subcategory_id'] == item['subcategory_id']) {
              itemSubcategoryName = subcat['subcategory_name']?.toString() ?? '';
              break;
            }
          }
        }
        
        bool matchesSearch = item['item_name']
                .toLowerCase()
                .contains(searchController.text.toLowerCase()) ||
            itemCategoryName.toLowerCase().contains(searchController.text.toLowerCase()) ||
            itemSubcategoryName.toLowerCase().contains(searchController.text.toLowerCase());
            
        // Filter by category_id
        bool matchesCategory = selectedCategoryId == 0 || 
            item['category_id'] == selectedCategoryId;
            
        // Filter by subcategory_id
        bool matchesSubcategory = selectedSubcategoryId == 0 || 
            item['subcategory_id'] == selectedSubcategoryId;
            
        // Filter by price range
        bool matchesPrice = (item['item_rentprice'] >= priceRange.start &&
            item['item_rentprice'] <= priceRange.end);
            
        // Filter by stock availability
        bool matchesStock = !showOnlyInStock || 
            (itemStocks[item['item_id']] ?? 0) > 0;
            
        return matchesSearch && matchesCategory && matchesSubcategory && matchesPrice && matchesStock;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Options',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade700),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Divider(height: 24, thickness: 1),
                    
                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category section
                            Row(
                              children: [
                                Icon(Icons.category_outlined, 
                                    color: Colors.blue.shade700, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCategory,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                  ),
                                  dropdownColor: Colors.white,
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setDialogState(() {
                                        // Update subcategories when category changes
                                        selectedCategory = newValue;
                                        
                                        if (newValue == 'All') {
                                          subcategories = ['All'];
                                          selectedSubcategory = 'All';
                                          selectedCategoryId = 0;
                                          selectedSubcategoryId = 0;
                                        } else {
                                          // Find the category_id for the selected category
                                          int? categoryId;
                                          for (var cat in categoryData) {
                                            if (cat['category_name'] == newValue) {
                                              categoryId = cat['category_id'];
                                              break;
                                            }
                                          }
                                          
                                          selectedCategoryId = categoryId ?? 0;
                                          
                                          if (categoryId != null && categoryToSubcategories.containsKey(categoryId)) {
                                            subcategories = ['All'];
                                            for (var subcat in categoryToSubcategories[categoryId]!) {
                                              subcategories.add(subcat['subcategory_name'].toString());
                                            }
                                          } else {
                                            subcategories = ['All'];
                                          }
                                          
                                          selectedSubcategory = 'All';
                                          selectedSubcategoryId = 0;
                                        }
                                      });
                                    }
                                  },
                                  items: categories.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            
                            // Subcategory section
                            Row(
                              children: [
                                Icon(Icons.view_list_outlined, 
                                    color: Colors.blue.shade700, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Subcategory',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSubcategory,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                  ),
                                  dropdownColor: Colors.white,
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setDialogState(() {
                                        selectedSubcategory = newValue;
                                        
                                        if (newValue == 'All') {
                                          selectedSubcategoryId = 0;
                                        } else {
                                          // Find the subcategory_id for the selected subcategory
                                          int? subcategoryId;
                                          if (selectedCategoryId != 0 && 
                                              categoryToSubcategories.containsKey(selectedCategoryId)) {
                                            for (var subcat in categoryToSubcategories[selectedCategoryId]!) {
                                              if (subcat['subcategory_name'] == newValue) {
                                                subcategoryId = subcat['subcategory_id'];
                                                break;
                                              }
                                            }
                                          }
                                          
                                          selectedSubcategoryId = subcategoryId ?? 0;
                                        }
                                      });
                                    }
                                  },
                                  items: subcategories.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            
                            // Price range section
                            Row(
                              children: [
                                Icon(Icons.attach_money_outlined, 
                                    color: Colors.blue.shade700, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Price Range (₹/day)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Price range labels
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '₹${priceRange.start.round()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '₹${priceRange.end.round()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Slider
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: Colors.blue.shade600,
                                inactiveTrackColor: Colors.blue.shade100,
                                thumbColor: Colors.white,
                                overlayColor: Colors.blue.shade200.withOpacity(0.2),
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                                overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                                valueIndicatorColor: Colors.blue.shade700,
                                valueIndicatorTextStyle: TextStyle(color: Colors.white),
                              ),
                              child: RangeSlider(
                                values: priceRange,
                                min: 0,
                                max: maxPrice,
                                divisions: 20,
                                labels: RangeLabels(
                                  '₹${priceRange.start.round()}',
                                  '₹${priceRange.end.round()}',
                                ),
                                onChanged: (RangeValues values) {
                                  setDialogState(() {
                                    priceRange = values;
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 24),
                            
                            // Stock availability
                            Row(
                              children: [
                                Transform.scale(
                                  scale: 0.9,
                                  child: Switch(
                                    value: showOnlyInStock,
                                    activeColor: Colors.blue.shade700,
                                    activeTrackColor: Colors.blue.shade200,
                                    onChanged: (bool value) {
                                      setDialogState(() {
                                        showOnlyInStock = value;
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Show only in-stock items',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(height: 0, thickness: 1),
                    SizedBox(height: 16),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.refresh, size: 18),
                          label: Text('Reset'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectedCategory = 'All';
                              selectedCategoryId = 0;
                              selectedSubcategory = 'All';
                              selectedSubcategoryId = 0;
                              subcategories = ['All'];
                              priceRange = RangeValues(0, maxPrice);
                              showOnlyInStock = false;
                            });
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _filterItems();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    searchController.removeListener(_filterItems);
    searchController.dispose();
    super.dispose();
  }

  Widget _buildRandomItemCard(Map<String, dynamic> item) {
    bool isInStock = (itemStocks[item['item_id']] ?? 0) > 0;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(itemId: item['item_id']),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Image
              Container(
                height: double.infinity,
                width: double.infinity,
                child: Image.network(
                  item['item_photo'],
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              // Text overlay
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item_name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price tag
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '₹${item['item_rentprice']}/day',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Stock indicator
                        if (isInStock)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Available',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Out of stock',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
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
              // Optional top left category tag
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getCategoryName(item['category_id']),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to get category name from category ID
  String _getCategoryName(int? categoryId) {
    if (categoryId == null) return 'Tool';
    
    for (var category in categoryData) {
      if (category['category_id'] == categoryId) {
        return category['category_name'] ?? 'Tool';
      }
    }
    
    return 'Tool';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman_outlined, size: 28),
            SizedBox(width: 8),
            Text(
              'RentIt',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade900],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.shopping_cart_outlined, color: Colors.blue.shade700),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade400, Colors.blue.shade900],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.home_outlined, color: Colors.blue.shade700),
              ),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_today_outlined, color: Colors.blue.shade700),
              ),
              title: Text('My Bookings'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Mybookings()));
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.settings_outlined, color: Colors.blue.shade700),
              ),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
              },
            ),
            Divider(),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout, color: Colors.red.shade400),
              ),
              title: Text('Logout', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => UserLoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchItems();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Your Tools',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Search tools...',
                                prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            child: IconButton(
                              icon: Icon(Icons.filter_list, color: Colors.blue.shade700),
                              onPressed: _showFilterDialog,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              if (randomItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.star_outline, color: Colors.blue.shade700),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Featured Tools',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${randomItems.length} items',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: randomItems.length,
                                itemBuilder: (context, index) {
                                  return _buildRandomItemCard(randomItems[index]);
                                },
                              ),
                            ),
                            SizedBox(height: 12),
                            // Page indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                randomItems.length,
                                (index) => AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  height: 8,
                                  width: _pageController.hasClients && 
                                         _pageController.page?.round() == index ? 24 : 8,
                                  decoration: BoxDecoration(
                                    color: _pageController.hasClients && 
                                         _pageController.page?.round() == index
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
              
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.grid_view, color: Colors.blue.shade700),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'All Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: EdgeInsets.all(16),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductPage(itemId: item['item_id']),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(item['item_photo']),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['item_name'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '₹${item['item_rentprice']}/day',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if ((itemStocks[item['item_id']] ?? 0) <= 0)
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Out of Stock',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
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
                        },
                      ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
