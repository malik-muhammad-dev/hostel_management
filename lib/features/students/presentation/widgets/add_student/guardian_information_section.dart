import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/student_form_controller.dart';
import 'form_feild.dart';
import 'form_section.dart';

class GuardianInformationSection extends StatelessWidget {
  final StudentFormController controller;

  const GuardianInformationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Guardian Information',
      subtitle: 'Parent or guardian contact details',
      icon: Icons.family_restroom_outlined,
      child: Column(
        children: [
          // -------------------------------------------------------------------
          // Guardian name + relationship
          // -------------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  controller: controller.guardianNameController,
                  label: 'Guardian / Parent Name',
                  hint: 'Enter full name',
                  required: true,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Obx(
                  () => FormDropdownWidget(
                    label: 'Relationship',
                    hint: 'Select relationship',
                    required: true,
                    value: controller.guardianRelationship.value,
                    options: const [
                      'Father',
                      'Mother',
                      'Brother',
                      'Sister',
                      'Uncle',
                      'Aunt',
                      'Grandfather',
                      'Grandmother',
                      'Other',
                    ],
                    onChanged: (value) {
                      controller.guardianRelationship.value = value;
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // -------------------------------------------------------------------
          // Guardian contact information
          // -------------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  controller: controller.guardianCnicController,
                  label: 'Guardian CNIC',
                  hint: 'XXXXX-XXXXXXX-X',
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: FormFieldWidget(
                  controller: controller.guardianPrimaryContactController,
                  label: 'Primary Contact',
                  hint: '03XX-XXXXXXX',
                  required: true,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: FormFieldWidget(
                  controller: controller.guardianAlternateContactController,
                  label: 'Alternate Contact',
                  hint: '03XX-XXXXXXX',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // -------------------------------------------------------------------
          // Occupation + address
          // -------------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  controller: controller.guardianOccupationController,
                  label: 'Occupation',
                  hint: 'Enter occupation',
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                flex: 2,
                child: FormFieldWidget(
                  controller: controller.guardianAddressController,
                  label: 'Guardian Address',
                  hint: 'Enter complete address',
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
