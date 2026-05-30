document.querySelectorAll('.produit').forEach(produit => {
    const description = produit.querySelector('.description').textContent.toLowerCase();
    const bouton = produit.querySelector('.btn-acheter');

    if (description.includes("hors stock")) {
        bouton.disabled = true;
        bouton.textContent = "Indisponible";
        bouton.style.opacity = "0.5";
        bouton.style.cursor = "not-allowed";
    } else if (description.includes("en stock")) {
        bouton.disabled = false;
        bouton.textContent = "Acheter";
    }
});