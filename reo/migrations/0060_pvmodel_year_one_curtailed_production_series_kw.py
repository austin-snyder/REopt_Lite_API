# Generated by Django 2.2.6 on 2020-05-19 20:19

import django.contrib.postgres.fields
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('reo', '0059_auto_20200508_2218'),
    ]

    operations = [
        migrations.AddField(
            model_name='pvmodel',
            name='year_one_curtailed_production_series_kw',
            field=django.contrib.postgres.fields.ArrayField(base_field=models.FloatField(blank=True, null=True), blank=True, null=True, size=None),
        ),
    ]
