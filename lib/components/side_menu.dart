import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/app_logo.dart';
import 'package:lms_admin/configs/assets_config.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/pages/home.dart';
import 'package:lms_admin/providers/auth_state_provider.dart';

final menuIndexProvider = StateProvider<int>((ref) => 0);

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
    required this.scaffoldKey,
    required this.role,
  }) : super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;
  final UserRoles role;

  @override
  Widget build(BuildContext context) {
    final bool isAuthor = role == UserRoles.author ? true : false;
    return Drawer(
      elevation: 0.5,
      backgroundColor: Theme.of(context).primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20, top: 30),
        child: Column(
          children: [
            const AppLogo(imageString: AssetsConfig.logoDark, height: 100, width: 240),
            const SizedBox(height: 30),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: isAuthor ? menuListAuthor.length : menuList.length,
              itemBuilder: (BuildContext context, int index) {
                String title = isAuthor ? menuListAuthor[index]![0] : menuList[index]![0];
                IconData icon = isAuthor ? menuListAuthor[index]![1] : menuList[index]![1];
                return _DrawerListTile(
                  title: title,
                  icon: icon,
                  index: index,
                  scaffoldKey: scaffoldKey,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerListTile extends ConsumerWidget {
  const _DrawerListTile({Key? key, required this.title, required this.icon, required this.index, required this.scaffoldKey}) : super(key: key);

  final String title;
  final IconData icon;
  final int index;
  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuIndex = ref.watch(menuIndexProvider);
    bool selected = menuIndex == index;

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        tileColor: selected ? Colors.white : Colors.transparent,
        onTap: () => _onTap(context, ref, menuIndex),
        horizontalTitleGap: 0.0,
        leading: Icon(
          icon,
          size: 20,
          color: selected ? Theme.of(context).primaryColor : Colors.white,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: selected ? Theme.of(context).primaryColor : Colors.white, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  void _onTap(context, WidgetRef ref, int newIndex) {
    ref.read(menuIndexProvider.notifier).update((state) => index);
    bool shouldAnimate = _shouldAnimate(index, newIndex);
    if (shouldAnimate) {
      ref.read(pageControllerProvider.notifier).state.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.ease);
    } else {
      ref.read(pageControllerProvider.notifier).state.jumpToPage(index);
    }
    if (scaffoldKey.currentState!.isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  bool _shouldAnimate(int currentIndex, int newIndex) {
    int dif = currentIndex - newIndex;
    if (dif > 1 || dif < -1) {
      return false;
    } else {
      return true;
    }
  }
}
