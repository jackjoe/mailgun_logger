const flash = document.getElementById('flash_message')

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
const showFlash = async () => {
    await sleep(500);
    flash.classList.add('visible');

    await sleep(5000);
    flash.classList.remove('visible');

    await sleep(1000);
    flash.remove();
};

if (flash) {
    showFlash()
}