import 'package:flutter/material.dart';

class CategoryIconPicker extends StatelessWidget {
  final IconData selectedIcon;
  final Function(IconData) onIconChanged;

  const CategoryIconPicker({
    Key? key,
    required this.selectedIcon,
    required this.onIconChanged,
  }) : super(key: key);

  static const List<IconData> _icons = [
    Icons.category,
    Icons.eco,
    Icons.apple,
    Icons.restaurant,
    Icons.set_meal,
    Icons.local_drink,
    Icons.grain,
    Icons.local_bar,
    Icons.fastfood,
    Icons.kitchen,
    Icons.ac_unit,
    Icons.shopping_cart,
    Icons.favorite,
    Icons.star,
    Icons.home,
    Icons.work,
    Icons.school,
    Icons.sports,
    Icons.music_note,
    Icons.movie,
    Icons.book,
    Icons.computer,
    Icons.phone,
    Icons.car_rental,
    Icons.flight,
    Icons.hotel,
    Icons.local_hospital,
    Icons.local_pharmacy,
    Icons.local_gas_station,
    Icons.local_grocery_store,
    Icons.local_laundry_service,
    Icons.local_parking,
    Icons.local_pizza,
    Icons.local_taxi,
    Icons.local_see,
    Icons.local_offer,
    Icons.local_play,
    Icons.local_post_office,
    Icons.local_print_shop,
    Icons.local_shipping,
    Icons.local_taxi,
    Icons.local_see,
    Icons.local_offer,
    Icons.local_play,
    Icons.local_post_office,
    Icons.local_print_shop,
    Icons.local_shipping,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _icons.length,
        itemBuilder: (context, index) {
          final icon = _icons[index];
          final isSelected = icon.codePoint == selectedIcon.codePoint;

          return GestureDetector(
            onTap: () => onIconChanged(icon),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}
