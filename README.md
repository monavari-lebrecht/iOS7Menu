# iOS7Menu

It is an easy to use menu, that fits perfectly in iOS7 Applications.


![Preview Image](http://monavari.de/fileadmin/data_archive/images/iOS7Menu/iOS7Menu_screen.png)

## How to install:

1. Install [CocoPods](http://cocoapods.org/)
2. Create a _Podfile_ in project root directory
3. Add the following line:
```
pod 'iOS7Menu', '~> 0.3'
```
4. Run ```pod install```

## First Steps:

1. Create a _Tabbed-Application_ in Xcode
2. Follow steps in _How to install_
3. Change Tab-ViewController-Class to _ISMViewController_
4. Run project


## How to use in existing project:

1. Add a UITabBarController to the storyboard
2. change class to _ISMViewController_
3. connect the menu controller with your view controller by clicking on the menu controller and – while holding ctrl – drag a connection to your own view controller.
4. Choose _viewcontrollers_ in the appearing menu
5. Repeat steps 3 and 4 to add all your view controllers to the menu

Video: http://www.youtube.com/watch?v=2nY8joGZ4iY&feature=youtu.be

You may also wanna have a look on http://monavari.de

<iframe width="560" height="315" src="//www.youtube.com/embed/2nY8joGZ4iY" frameborder="0" allowfullscreen></iframe>
