import 'dart:async';                                                   // ใช้สำหรับ Timer เพื่อให้ Splash Screen หน่วงเวลาก่อนเข้าแอปจริง
import 'package:flutter/material.dart';                                // ใช้ widget ต่าง ๆ ของ Flutter เช่น Scaffold, Text, Icon
import 'main.dart';                                                    // เรียกหน้า AppShell จากไฟล์ main.dart เพื่อไปหน้าโครงหลักของแอป

class SplashScreen extends StatefulWidget {
  // สร้างหน้า SplashScreen แบบ Stateful เพราะมีการใช้ Timer ใน initState()


  const SplashScreen({super.key});


  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

//initState() จะถูกเรียกทันทีเมื่อเปิดหน้า SplashScreen
//ใช้สำหรับตั้ง Timer ให้หน่วงเวลาก่อนเข้าแอป
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // หน่วง 2.5 วินาที แล้วเข้าหน้า AppShell สร้าง Timer 2.5 วินาที (2500ms)
    //เมื่อเวลาครบ ให้ทำงานใน callback (เข้า AppShell)
    Timer(const Duration(milliseconds: 2500), () {
      
      //เช็กว่า widget ยังอยู่ในหน้าจออยู่ไหม (กัน error ถ้าผู้ใช้ปิดหน้าเร็วก่อน timer ทำงาน)
      if (!mounted) return;

      //ไปหน้า AppShell() ซึ่งเป็นโครงหลักของแอป
      //ใช้ pushReplacement() → แทนที่ SplashScreen ทิ้งไปเลย (จะไม่ย้อนกลับมาหน้านี้อีก)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    });
  }

  //ส่วน UI ของ SplashScreen
  @override
  Widget build(BuildContext context) {

    //ดึงชุดสีหลักของแอป เช่น primary, secondary
    //ใช้เพื่อกำหนดสีพื้นหลังให้ Splash Screen
    final scheme = Theme.of(context).colorScheme;

    //สร้างโครงหน้าแบบ Scaffold
    //ใช้ สี primary ของธีม เป็นพื้นหลังของ Splash
    return Scaffold(
      backgroundColor: scheme.primary,

      //จัดวาง content ตรงกลางหน้าจอ
      //ใช้ Column เพื่อวางไอคอน, ชื่อแอป, แถบโหลด เรียงจากบนลงล่าง
      //mainAxisSize.min → ให้ Column หดเท่าที่จำเป็น (ไม่ยืดเต็มจอ)
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [


            //โลโก้แอป (ไอคอนติ๊กถูก)
            //ขนาด 96 px
            //สีขาว
            const Icon(Icons.task_alt, size: 96, color: Colors.white),

            //เว้นช่องว่าง 16px ระหว่างไอคอนกับชื่อแอป
            const SizedBox(height: 16),



            const Text(
              'ToDo-List App',                    //ชื่อแอป
              style: TextStyle(                   //สีขาว
                color: Colors.white,
                fontSize: 24,                     //ตัวใหญ่ 24px
                fontWeight: FontWeight.w800,      //น้ำหนักตัวหนา (800)
              ),
            ),

            //เว้นช่องนิดหน่อยก่อนแถบโหลด
            const SizedBox(height: 12),


            //ทำให้ดูเหมือนกำลังโหลด พร้อมเข้าแอป
            SizedBox(
              width: 120,                               //แสดงแถบโหลดแบบบาง ๆ ยาว 120px
              child: LinearProgressIndicator(
                color: Colors.white,                  //สีขาว
                backgroundColor: Colors.white24,      //พื้นหลังสีขาวโปร่ง 24%
              ),
            ),
          ],
        ),
      ),
    );
  }
}
