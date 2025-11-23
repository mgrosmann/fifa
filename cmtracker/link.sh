#!/bin/bash
read -p "homme ou femme (m/f)" gender
if [ "$gender" = "m" ]; then
  gender="male"
elif [ "$gender" = "f" ]; then
  gender="female"
else
  echo "Entrée invalide. Veuillez entrer 'm' pour homme ou 'f' pour femme."
  exit 1
fi
read -p "ID de l'équipe :" teamid
read -p "Potentiel minimum :" min_potential
read -p "Potentiel maximum :" max_potential
read -p "Note globale minimum :" min_overall
read -p "Note globale maximum :" max_overall
echo "Voici l'URL générée :"
echo "https://cmtracker.net/players?sort=overallrating%3Adesc&limit=25&page=0&ci=&sct=&sse=&team__in=$teamid&potential__gte=$min_potential&potential__lte=$max_potential&overallrating__gte=$min_overall&overallrating__lte=$max_overall&gender__in=$gender&db=691faa5f6610a3f2739a5a3c"