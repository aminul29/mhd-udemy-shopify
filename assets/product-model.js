


// 1. Create a class that extends HTMLElement
class ProductModel extends HTMLElement {
    // 2. Create a constructor
    constructor(){
        super();
        // 4. Call the openModelModal method
        this.openModelModal();
    }

    // 8. Create a method to get the media ID
    getMediaID(){
        // 11... add the <product-model data-media-id="{{ media.id }}"> in the product-media.liquid to specify the product
        // 12. Get the media ID from the attribute
        const id = this.getAttribute('data-media-id');
        // 13. Return the media ID
        return id;        
    }


    // 10. Create a method to get the modal
    getModal(){
        // 15. Get the modal element
        const modal = document.getElementById('productModelModal');
        // 16. Return the modal
        return modal;
    }

    // 3. Create a method to open the modal
    openModelModal(){
        // 6. Log the element, it checks if the method openModelModal is working
        // console.log("The element is working");

        //7. We need two elements to display the modal, first mediaID
        const mediaID = this.getMediaID();

        // 9. second the modal itself
        const modal = this.getModal();

        // 14. console log media id
        // console.log(mediaID);

        // 17. console log modal, we should have the model window element
        // console.log(modal);

        // 18. check if correspondent 3d model exist with the media ID, if not return
        if(!mediaID) return;

        // 19. add the id id="productModelOpenButton_{{ media.id }}" in modal button inside product-media.liquid 
        // 20. Get the open modal button
        const openModalButton = this.querySelector(`button[id="productModelOpenButton_${mediaID}"]`);

        // 21. Add a click event listener to the open modal button
        openModalButton.addEventListener('click', (e) => {
            // 22. reset the Model body of template-product.liquid to empty string
            modal.querySelector("#body").innerHTML = "";

            // 23. Get the template element of the <product-model> element
            const template = document.querySelector(`product-model[data-media-id="${mediaID}"] > template`);

            // console log template to see if its working, it should log the template element
            //console.log(template);

            // 24. Clone the template
            const clone = template.content.cloneNode(true);

            // 25. console log the clone, it should print the template element's content
            //console.log(clone);

            // 26. Append the clone to the model body
            modal.querySelector("#body").appendChild(clone);

            // 27. change the reveal attribute of the model-viewer from interaction to auto
            modal.querySelector("#body > model-viewer").setAttribute("reveal", "auto");
        });

    }

}
// 5. Register the custom element product-model
const productModel = customElements.define('product-model', ProductModel);
